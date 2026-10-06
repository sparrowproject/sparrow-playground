import Foundation
import Observation
import SparrowStorageBase
import SparrowTabs
import SparrowUIFoundation

typealias TabGroupStoreDependencies
  = StoragePathsProviding
  & TabSystemProviding

@MainActor
final class TabGroupStore {
  init(dependencies: TabGroupStoreDependencies) {
    self.dependencies = dependencies
  }

  func readData(tabSystemInitializer: TabSystemInitializer) async {
    for groupData in await readAllGroups() {
      tabSystemInitializer.insertTabGroup(
        id: groupData.id,
        tabIDs: groupData.tabIDs,
        selectedTabID: groupData.selectedTabID,
      )
      initialGroupData[groupData.id] = groupData
    }
  }

  func setUpObservers() {
    observationTask = .init(operation: observeGroups)
  }

  private let dependencies: TabGroupStoreDependencies
  private var observationTask: Task<Void, Never>?
  private var writers = [TabGroupID: TabGroupWriter]()
  private var initialGroupData = [TabGroupID: TabGroupData]()

  private lazy var storagePath: URL = {
    let path = dependencies.storagePaths.userDataDirectory.appendingPathComponent("tabgroups")
    try! FileManager.default.createDirectory(
      at: path,
      withIntermediateDirectories: true,
    )
    return path
  }()

  private func observeGroups() async {
    let tabSystemModel = dependencies.tabSystem.model

    for await groupIDs in Observations({
      tabSystemModel.groups.keys
    }) {
      var oldWriters = writers
      var newWriters = [TabGroupID: TabGroupWriter]()

      for groupID in groupIDs {
        if let writer = oldWriters.removeValue(forKey: groupID) {
          newWriters[groupID] = writer
        } else {
          newWriters[groupID] = .init(
            groupID: groupID,
            groupModel: tabSystemModel.groups[groupID]!,
            directory: storagePath,
            existingGroupData: initialGroupData[groupID],
          )
        }
      }

      writers = newWriters
      for writer in oldWriters.values {
        writer.removeFile()
      }
    }
  }

  private func readAllGroups() async -> [TabGroupData] {
    await withCheckedContinuation { continuation in
      DispatchQueue(label: "tabgroups-reader").async { [storagePath] in
        var result = [TabGroupData]()
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
            let groupData = try decoder.decode(TabGroupData.self, from: data)
            result.append(groupData)
          } catch {
            print(">>> error reading tab group data: \(error)")
          }
        }
        continuation.resume(returning: result)
      }
    }
  }
}

extension TabGroupStore: StorageComponent {
  func shutdown() -> ShutdownTask? {
    print(">>> TabGroupStore.shutdown")

    observationTask?.cancel()
    observationTask = nil

    for writer in writers.values {
      writer.shutdown()
    }

    return nil
  }
}

@MainActor
private final class TabGroupWriter {
  init(groupID: TabGroupID, groupModel: TabGroupModel, directory: URL, existingGroupData: TabGroupData?) {
    self.groupID = groupID
    self.groupModel = groupModel

    self.objectWriter = .init(fileURL: directory.appendingPathComponent(groupID.id))
    objectWriter.currentObject = existingGroupData

    observationTask = .init(operation: observeGroup)
  }

  func removeFile() {
    objectWriter.remove()
  }

  func shutdown() {
    observationTask?.cancel()
    observationTask = nil

    objectWriter.write(TabGroupData(fromModel: groupModel))
    objectWriter.flush()
  }

  private let groupID: TabGroupID
  private let groupModel: TabGroupModel
  private let objectWriter: ObjectWriter<TabGroupData>
  private var observationTask: Task<Void, Never>?

  private func observeGroup() async {
    for await groupData in Observations({ [groupModel] in
      TabGroupData(fromModel: groupModel)
    }) {
      objectWriter.write(groupData)
    }
  }
}

extension TabGroupData {
  @MainActor
  init(fromModel groupModel: TabGroupModel) {
    self.init(
      id: groupModel.id,
      tabIDs: groupModel.tabIDs.elements,
      selectedTabID: groupModel.selectedTabModel.id.nilIfInvalid,
    )
  }
}