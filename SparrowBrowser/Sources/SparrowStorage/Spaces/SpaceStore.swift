import Foundation
import Observation
import SparrowSpaces
import SparrowStorageBase
import SparrowTabs
import SparrowToolbelt

@MainActor
public protocol SpaceStore: StorageComponent {
  var model: SpaceGridModel { get }

  func initialize() async
}

public protocol SpaceStoreProviding {
  @MainActor
  var spaceStore: SpaceStore { get }
}

public typealias SpaceStoreDependencies
  = StoragePathsProviding

extension Factory where Interface == SpaceStore {
  public static func makeDefaultInstance(dependencies: SpaceStoreDependencies) -> SpaceStore {
    DefaultSpaceStore(dependencies: dependencies)
  }
}

final class DefaultSpaceStore: SpaceStore {
  init(dependencies: SpaceStoreDependencies) {
    self.dependencies = dependencies
  }

  let model = SpaceGridModel()

  func initialize() async {
    let spaceData = await readSpaceData()

    for (key, groupID) in spaceData.elements {
      model[row: key.row, col: key.col] = groupID
    }

    observationTask = .init(operation: observeSpaceGridModel)
  }

  func shutdown() -> ShutdownTask? {
    observationTask?.cancel()
    observationTask = nil

    objectWriter.write(SpaceData(fromModel: model))
    objectWriter.flush()

    return nil
  }

  private let dependencies: SpaceStoreDependencies
  private var observationTask: Task<Void, Never>?

  private lazy var storagePath = dependencies.storagePaths.userDataDirectory.appendingPathComponent("spaces.json")
  private lazy var objectWriter = ObjectWriter<SpaceData>(fileURL: storagePath)

  private func readSpaceData() async -> SpaceData {
    await withCheckedContinuation { continuation in
      DispatchQueue(label: "spaces-reader").async { [storagePath] in
        var result = SpaceData()
        let decoder = JSONDecoder()
        do {
          let data = try Data(contentsOf: storagePath)
          result = try decoder.decode(SpaceData.self, from: data)
        } catch {
          print(">>> error reading spaces: \(error)")
        }
        continuation.resume(returning: result)
      }
    }
  }

  private func observeSpaceGridModel() async {
    for await spaceData in Observations({ [model] in
      SpaceData(fromModel: model)
    }) {
      objectWriter.write(spaceData)
    }
  }
}

extension SpaceData {
  @MainActor
  fileprivate init(fromModel model: SpaceGridModel) {
    var elements = [SpaceData.Key: TabGroupID]()
    for (key, groupID) in model.savedGroups {
      elements[Key(row: key.row, col: key.col)] = groupID
    }
    self.init(elements: elements)
  }
}