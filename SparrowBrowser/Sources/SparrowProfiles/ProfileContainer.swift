import Foundation
import SparrowDownloads
import SparrowHistory
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
  : DownloadsManagerProviding
  , NetworkServiceProviding
  , ProfileIDProviding
  , ProfileModelProviding
  , SpaceGridModelProviding
  , SuggestServiceProviding
  , TabSystemProviding
  , TypedHistoryProviding
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
  public var storageSystem: StorageSystem? {
    (self as? StorageSystemProviding)?.storageSystem
  }

  @MainActor
  public var tabUndoManager: TabUndoManager? {
    (self as? TabUndoManagerProviding)?.tabUndoManager
  }
}

@MainActor
struct NormalProfileContainer
    : LiveContainer
    , ProfileContainer
    , StorageSystemProviding
    , TabUndoManagerProviding
{
  init(dependencies: ProfileContainerDependencies, profileModel: ProfileModel) {
    // MODULE DEPENDENCY TREE

    let storagePaths = ProfileStoragePaths(index: profileModel.index, rootPaths: dependencies.storagePaths)

    let downloadsManager = {
      @MainActor
      struct Container: DownloadsManagerDependencies {}
      let container = Container()
      return Factory<DownloadsManager>.makeDefaultInstance(dependencies: container)
    }()

    let networkService = {
      @MainActor
      struct Container: NetworkServiceDependencies {}
      let container = Container()
      return Factory<NetworkService>.makeDefaultInstance(dependencies: container)
    }()

    let typedHistory = {
      @MainActor
      struct Container: TypedHistoryDependencies {}
      let container = Container()
      return Factory<TypedHistory>.makeDefaultInstance(dependencies: container)
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

    let tabSystemDelegate = {
      @MainActor
      struct Container: ProfileTabSystemDelegateDependencies {
        let downloadsManager: DownloadsManager
        let windowSystemModel: WindowSystemModel
      }
      let container = Container(
        downloadsManager: downloadsManager,
        windowSystemModel: dependencies.windowSystemModel,
      )
      return ProfileTabSystemDelegate(dependencies: container)
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
    tabSystem.delegate = tabSystemDelegate

    let tabUndoManager = {
      @MainActor
      struct Container: TabUndoManagerDependencies {
        let tabSystem: TabSystem
      }
      let container = Container(
        tabSystem: tabSystem,
      )
      return Factory<TabUndoManager>.makeDefaultInstance(dependencies: container)
    }()

    let storageSystem = {
      @MainActor
      struct Container: StorageSystemDependencies {
        let downloadsManager: DownloadsManager
        let spaceStore: SpaceStore
        let storagePaths: StoragePaths
        let tabSystem: TabSystem
        let webHistory: WebHistory
      }
      let container = Container(
        downloadsManager: downloadsManager,
        spaceStore: spaceStore,
        storagePaths: storagePaths,
        tabSystem: tabSystem,
        webHistory: webHistory,
      )
      return Factory<StorageSystem>.makeDefaultInstance(dependencies: container)
    }()

    // Store exported modules:

    self.dependencies = dependencies
    self.downloadsManager = downloadsManager
    self.networkService = networkService
    self.profileModel = profileModel
    self.spaceGridModel = spaceStore.model
    self.storageSystem = storageSystem
    self.suggestService = suggestService
    self.tabSystem = tabSystem
    self.tabSystemDelegate = tabSystemDelegate
    self.tabUndoManager = tabUndoManager
    self.typedHistory = typedHistory
    self.webHistory = webHistory
    windowSystemModel = dependencies.windowSystemModel
  }

  let dependencies: ProfileContainerDependencies
  let downloadsManager: DownloadsManager
  let networkService: NetworkService
  let profileModel: ProfileModel
  let spaceGridModel: SpaceGridModel
  let storageSystem: StorageSystem
  let suggestService: SuggestService
  let tabSystem: TabSystem
  let tabSystemDelegate: TabSystemDelegate
  let tabUndoManager: TabUndoManager
  let typedHistory: TypedHistory
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

    let downloadsManager = {
      @MainActor
      struct Container: DownloadsManagerDependencies {}
      let container = Container()
      return Factory<DownloadsManager>.makeDefaultInstance(dependencies: container)
    }()

    let networkService = {
      @MainActor
      struct Container: NetworkServiceDependencies {}
      let container = Container()
      return Factory<NetworkService>.makeDefaultInstance(dependencies: container)
    }()

    let typedHistory = Factory<TypedHistory>.makeReadonlyWrapper(source: normalContainer.typedHistory)

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

    let tabSystemDelegate = {
      @MainActor
      struct Container: ProfileTabSystemDelegateDependencies {
        let downloadsManager: DownloadsManager
        let windowSystemModel: WindowSystemModel
      }
      let container = Container(
        downloadsManager: downloadsManager,
        windowSystemModel: normalContainer.windowSystemModel,
      )
      return ProfileTabSystemDelegate(dependencies: container)
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
    tabSystem.delegate = tabSystemDelegate

    // Store exported modules:

    self.downloadsManager = downloadsManager
    self.networkService = networkService
    self.spaceGridModel = spaceGridModel
    self.suggestService = suggestService
    self.tabSystem = tabSystem
    self.tabSystemDelegate = tabSystemDelegate
    self.typedHistory = typedHistory
    self.webHistory = webHistory
    windowSystemModel = normalContainer.windowSystemModel
  }

  let downloadsManager: DownloadsManager
  let networkService: NetworkService
  let profileModel: ProfileModel
  let spaceGridModel: SpaceGridModel
  let suggestService: SuggestService
  let tabSystem: TabSystem
  let tabSystemDelegate: TabSystemDelegate
  let typedHistory: TypedHistory
  let webHistory: WebHistory
  let windowSystemModel: WindowSystemModel

  private let normalContainer: ProfileContainer
}