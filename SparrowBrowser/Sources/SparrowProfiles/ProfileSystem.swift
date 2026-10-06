import OrderedCollections
import SparrowProfileModel
import SparrowStorage
import SparrowToolbelt

@MainActor
public protocol ProfileSystem: StorageComponent {
  var model: ProfileSystemModel { get }

  func initialize() async

  func model(for: ProfileID) -> ProfileModel
  func container(for: ProfileID) -> ProfileContainer
}

public protocol ProfileSystemProviding {
  @MainActor
  var profileSystem: ProfileSystem { get }
}

public typealias ProfileSystemDependencies
  = ProfileContainerDependencies

extension Factory where Interface == ProfileSystem {
  public static func makeDefaultInstance(dependencies: ProfileSystemDependencies) -> ProfileSystem {
    DefaultProfileSystem(dependencies: dependencies)
  }
}

final class DefaultProfileSystem: ProfileSystem {
  init(dependencies: ProfileSystemDependencies) {
    self.dependencies = dependencies
  }

  let model = ProfileSystemModel()

  func initialize() async {
    // For each profile, initialize its storage system.
    // TODO: Actually read profile information from disk.

    for id in [ProfileID.default] {
      await container(for: id).storageSystem?.initialize()
    }
  }

  func shutdown() -> Task<Void, Never>? {
    var tasks = [Task<Void, Never>]()

    for id in [ProfileID.default] {
      if let task = container(for: id).storageSystem?.shutdown() {
        tasks.append(task)
      }
    }

    return tasks.isEmpty ? nil : tasks.joined()
  }

  func model(for profileID: ProfileID) -> ProfileModel {
    guard profileID.kind == .normal else {
      return .init(
        id: profileID,
        index: -1,
        title: "",
      )
    }

    if let profileModel = model.normalProfiles[profileID] {
      return profileModel
    }

    let mutator = model.mutate()
    let profileModel = mutator.addProfile(
      id: profileID,
      index: model.normalProfiles.count,
      title: "", // TODO
    )
    mutator.commit()

    return profileModel
  }

  func container(for profileID: ProfileID) -> ProfileContainer {
    if let container = containers[profileID] {
      return container
    }

    let profileModel = model(for: profileID)

    let container: ProfileContainer =
      switch profileID.kind {
      case .normal:
        NormalProfileContainer(dependencies: dependencies, profileModel: profileModel)
      case .incognito:
        IncognitoProfileContainer(
          profileModel: profileModel,
          normalContainer: container(for: profileID.normalVariant),
        )
      }

    containers[profileID] = container
    return container
  }

  private let dependencies: ProfileSystemDependencies
  private var containers = [ProfileID: ProfileContainer]()
}