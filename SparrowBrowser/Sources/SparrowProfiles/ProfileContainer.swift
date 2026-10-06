import Foundation
import SparrowNetwork
import SparrowProfileModel
import SparrowSpaces
import SparrowStorage
import SparrowStorageBase
import SparrowSuggest
import SparrowTabs
import SparrowToolbelt
import SparrowWeb
import SparrowWindow
import SparrowWindowModel

public protocol ProfileContainer
  : NetworkServiceProviding
  , ProfileIDProviding
  , ProfileModelProviding
  , SpaceGridModelProviding
  , SuggestServiceProviding
  , TabSystemProviding
  , WebHistoryProviding
  , WindowSystemModelProviding
{}

public typealias ProfileContainerDependencies
  = StoragePathsProviding
  & WindowSystemModelProviding

// TODO: Expose ProfileSystemModelProviding as well so a browser window can
// offer a switcher to access other profiles.

extension ProfileContainer {
  @MainActor
  var storageSystem: StorageSystem? {
    (self as? StorageSystemProviding)?.storageSystem
  }
}

@MainActor
struct NormalProfileContainer: LiveContainer, ProfileContainer, StorageSystemProviding {
  init(dependencies: ProfileContainerDependencies, profileModel: ProfileModel) {
    // MODULE DEPENDENCY TREE

    let storagePaths = ProfileStoragePaths(index: profileModel.index, rootPaths: dependencies.storagePaths)

    let networkService = {
      @MainActor
      struct Container: NetworkServiceDependencies {}
      let container = Container()
      return Factory<NetworkService>.makeDefaultInstance(dependencies: container)
    }()

    let suggestService = {
      @MainActor
      struct Container: SuggestServiceDependencies {
        let networkService: NetworkService
      }
      let container = Container(
        networkService: networkService,
      )
      return Factory<SuggestService>.makeDefaultInstance(dependencies: container)
    }()

    let (spaceStore, webHistory) = {
      @MainActor
      struct Container: PersistentWebHistoryDependencies {
        let storagePaths: StoragePaths
      }
      let container = Container(
        storagePaths: storagePaths,
      )
      return (
        Factory<SpaceStore>.makeDefaultInstance(dependencies: container),
        Factory<WebHistory>.makePersistentInstance(dependencies: container)
      )
    }()

    let webContentFactory = {
      @MainActor
      struct Container: WebContentFactoryDependencies {
        let storagePaths: StoragePaths
        let webHistory: WebHistory
      }
      let container = Container(
        storagePaths: dependencies.storagePaths,
        webHistory: webHistory,
      )
      return Factory<WebContentFactory>.makeDefaultInstance(
        dependencies: container,
        partition: .init(identifier: profileModel.id.token, kind: .persistent),
      )
    }()

    let tabSystem = {
      @MainActor
      struct Container: TabSystemDependencies {
        let webContentFactory: WebContentFactory
      }
      let container = Container(
        webContentFactory: webContentFactory,
      )
      return Factory<TabSystem>.makeDefaultInstance(dependencies: container)
    }()

    let storageSystem = {
      @MainActor
      struct Container: StorageSystemDependencies {
        let spaceStore: SpaceStore
        let storagePaths: StoragePaths
        let tabSystem: TabSystem
        let webHistory: WebHistory
      }
      let container = Container(
        spaceStore: spaceStore,
        storagePaths: storagePaths,
        tabSystem: tabSystem,
        webHistory: webHistory,
      )
      return Factory<StorageSystem>.makeDefaultInstance(dependencies: container)
    }()

    // Store exported modules:

    self.dependencies = dependencies
    self.networkService = networkService
    self.profileModel = profileModel
    self.spaceGridModel = spaceStore.model
    self.storageSystem = storageSystem
    self.suggestService = suggestService
    self.tabSystem = tabSystem
    self.webHistory = webHistory
    windowSystemModel = dependencies.windowSystemModel
  }

  let dependencies: ProfileContainerDependencies
  let networkService: NetworkService
  let profileModel: ProfileModel
  let spaceGridModel: SpaceGridModel
  let storageSystem: StorageSystem
  let suggestService: SuggestService
  let tabSystem: TabSystem
  let webHistory: WebHistory
  let windowSystemModel: WindowSystemModel
}

@MainActor
struct IncognitoProfileContainer: LiveContainer, ProfileContainer {
  init(profileModel: ProfileModel, normalContainer: ProfileContainer) {
    self.profileModel = profileModel
    self.normalContainer = normalContainer

    // MODULE DEPENDENCY TREE

    let spaceGridModel = SpaceGridModel()

    let webHistory = Factory<WebHistory>.makeInMemoryInstance()

    let networkService = {
      @MainActor
      struct Container: NetworkServiceDependencies {}
      let container = Container()
      return Factory<NetworkService>.makeDefaultInstance(dependencies: container)
    }()

    let suggestService = {
      @MainActor
      struct Container: SuggestServiceDependencies {
        let networkService: NetworkService
      }
      let container = Container(
        networkService: networkService,
      )
      return Factory<SuggestService>.makeDefaultInstance(dependencies: container)
    }()

    let webContentFactory = {
      @MainActor
      struct Container: WebContentFactoryDependencies {
        let storagePaths: StoragePaths
        let webHistory: WebHistory
      }
      let container = Container(
        storagePaths: (normalContainer as! NormalProfileContainer).dependencies.storagePaths,
        webHistory: webHistory,
      )
      // TODO: Needs to be `makeIncognitoInstance`.
      return Factory<WebContentFactory>.makeDefaultInstance(
        dependencies: container,
        partition: .init(identifier: profileModel.id.token, kind: .incognito),
      )     
    }()

    let tabSystem = {
      @MainActor
      struct Container: TabSystemDependencies {
        let webContentFactory: WebContentFactory
      }
      let container = Container(
        webContentFactory: webContentFactory,
      )
      return Factory<TabSystem>.makeDefaultInstance(dependencies: container)
    }()

    // Store exported modules:

    self.networkService = networkService
    self.spaceGridModel = spaceGridModel
    self.suggestService = suggestService
    self.tabSystem = tabSystem
    self.webHistory = webHistory
    windowSystemModel = normalContainer.windowSystemModel
  }

  let networkService: NetworkService
  let profileModel: ProfileModel
  let spaceGridModel: SpaceGridModel
  let suggestService: SuggestService
  let tabSystem: TabSystem
  let webHistory: WebHistory
  let windowSystemModel: WindowSystemModel

  private let normalContainer: ProfileContainer
}