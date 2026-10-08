import Foundation
import Observation
import SparrowStorageBase
import SparrowToolbelt
import SparrowWindowModel

public protocol WindowDataStore: StorageComponent {
  var model: WindowSystemModel { get }

  func initialize() async
}

public protocol WindowDataStoreProviding {
  @MainActor
  var windowDataStore: WindowDataStore { get }
}

public typealias WindowDataStoreDependencies
  = StoragePathsProviding

extension Factory where Interface == WindowDataStore {
  public static func makeDefaultInstance(dependencies: WindowDataStoreDependencies) -> WindowDataStore {
    DefaultWindowDataStore(dependencies: dependencies)
  }
}

private final class DefaultWindowDataStore: WindowDataStore {
  init(dependencies: WindowDataStoreDependencies) {
    self.dependencies = dependencies
  }

  let model = WindowSystemModel()

  func initialize() async {
    let windowList = await readWindowList().map {
      $0.makeWindowModel()
    }

    // TODO: Map WindowData to {Browser}WindowModel

    model.windows = .init(
      uniqueKeysWithValues: windowList.map { ($0.id, $0) },
    )

    observationTask = .init(operation: observeWindowList)
  }

  func shutdown() -> ShutdownTask? {
    observationTask?.cancel()
    observationTask = nil

    objectWriter.write(Array(model.persistentWindows))
    objectWriter.flush()

    return nil
  }

  private let dependencies: WindowDataStoreDependencies
  private var observationTask: Task<Void, Never>?

  private lazy var storagePath = dependencies.storagePaths.userDataDirectory.appendingPathComponent("windows.json")
  private lazy var objectWriter = ObjectWriter<[WindowData]>(fileURL: storagePath)

  private func readWindowList() async -> [WindowData] {
    await withCheckedContinuation { continuation in
      DispatchQueue(label: "windows-reader").async { [storagePath] in
        var result = [WindowData]()
        let decoder = JSONDecoder()
        do {
          let data = try Data(contentsOf: storagePath)
          result = try decoder.decode([WindowData].self, from: data)
        } catch {
          print(">>> error reading window list: \(error)")
        }
        continuation.resume(returning: result)
      }
    }
  }

  private func observeWindowList() async {
    for await windowList in Observations({ [model] in
      model.persistentWindows
    }) {
      objectWriter.write(Array(windowList))
    }
  }
}

extension WindowSystemModel {
  var persistentWindows: [WindowData] {
    windows.values.filter({
      !$0.isIncognito
    }).map {
      WindowData.from($0)
    }
  }
}