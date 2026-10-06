import Foundation
import Observation
import SparrowStorageBase
import SparrowTabs

typealias TabStoreDependencies
  = StoragePathsProviding
  & TabSystemProviding

@MainActor
final class TabStore {
  init(dependencies: TabStoreDependencies) {
    self.dependencies = dependencies
  }

  func readData(tabSystemInitializer: TabSystemInitializer) async {
    for tabData in await readAllTabs() {
      tabSystemInitializer.insertTab(
        id: tabData.id,
        url: tabData.url,
        title: tabData.title,
        faviconURL: tabData.faviconURL,
        interactionState: tabData.interactionState,
      )
      initialTabData[tabData.id] = tabData
    }
  }

  func setUpObservers() {
    observationTask = .init(operation: observeTabs)
  }

  private let dependencies: TabStoreDependencies
  private var observationTask: Task<Void, Never>?
  private var writers = [TabID: TabWriter]()
  private var initialTabData = [TabID: TabData]()

  private lazy var storagePath: URL = {
    let path = dependencies.storagePaths.userDataDirectory.appendingPathComponent("tabs")
    try! FileManager.default.createDirectory(
      at: path,
      withIntermediateDirectories: true,
    )
    return path
  }()

  private func observeTabs() async {
    let tabSystemModel = dependencies.tabSystem.model

    for await tabIDs in Observations({
      tabSystemModel.tabs.keys
    }) {
      var oldWriters = writers
      var newWriters = [TabID: TabWriter]()

      for tabID in tabIDs {
        if let writer = oldWriters.removeValue(forKey: tabID) {
          newWriters[tabID] = writer
        } else {
          newWriters[tabID] = .init(
            tabID: tabID,
            tabModel: tabSystemModel.tabs[tabID]!,
            directory: storagePath,
            existingTabData: initialTabData[tabID],
          )
        }
      }

      writers = newWriters
      for writer in oldWriters.values {
        writer.removeFile()
      }
    }
  }

  private func readAllTabs() async -> [TabData] {
    await withCheckedContinuation { continuation in
      DispatchQueue(label: "tabs-reader").async { [storagePath] in
        var result = [TabData]()
        let fileURLs: [URL]
        do {
          fileURLs = try FileManager.default.contentsOfDirectory(
            at: storagePath,
            includingPropertiesForKeys: nil,
          )
        } catch {
          print(">>> error reading contents of directory: \(storagePath)")
          return
        }
        let decoder = JSONDecoder()
        for fileURL in fileURLs {
          do {
            let data = try Data(contentsOf: fileURL)
            let tabData = try decoder.decode(TabData.self, from: data)
            result.append(tabData)
          } catch {
            print(">>> error reading tab data: \(error)")
          }
        }
        continuation.resume(returning: result)
      }
    }
  }
}

extension TabStore: StorageComponent {
  func shutdown() -> ShutdownTask? {
    print(">>> TabStore.shutdown")

    observationTask?.cancel()
    observationTask = nil

    for writer in writers.values {
      writer.shutdown()
    }

    return nil
  }
}

@MainActor
private final class TabWriter {
  init(tabID: TabID, tabModel: TabModel, directory: URL, existingTabData: TabData?) {
    self.tabID = tabID
    self.tabModel = tabModel

    objectWriter = .init(fileURL: directory.appendingPathComponent(tabID.rawValue.uuidString))
    objectWriter.currentObject = existingTabData

    observationTask = .init(operation: observeTab)
  }

  func removeFile() {
    objectWriter.remove()
  }

  func shutdown() {
    observationTask?.cancel()
    observationTask = nil

    objectWriter.write(.init(fromModel: tabModel))
    objectWriter.flush()
  }

  private let tabID: TabID
  private let tabModel: TabModel
  private let objectWriter: ObjectWriter<TabData>
  private var observationTask: Task<Void, Never>?

  private func observeTab() async {
    for await tabData in Observations({ [tabModel] in
      TabData(fromModel: tabModel)
    }) {
      objectWriter.write(tabData)
    }
  }
}

extension TabData {
  @MainActor
  init(fromModel tabModel: TabModel) {
    self.init(
      id: tabModel.id,
      url: tabModel.url,
      title: tabModel.title,
      faviconURL: tabModel.faviconURL,
      interactionState: tabModel.interactionState,
    )
  }
}