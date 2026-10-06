import SparrowStorage
import SparrowStorageBase
import SparrowToolbelt
import SparrowProfiles
import SparrowWindowManager
import SparrowWindowModel

@MainActor
struct AppContainer {
  init() {
    // MODULE DEPENDENCY TREE

    let rootStoragePaths = Factory<StoragePaths>.makeRootInstance()

    let windowDataStore = {
      @MainActor
      struct Container: WindowDataStoreDependencies {
        let storagePaths: StoragePaths
      }
      let container = Container(
        storagePaths: rootStoragePaths,
      )
      return Factory<WindowDataStore>.makeDefaultInstance(dependencies: container)
    }()

    let profileSystem = {
      @MainActor
      struct Container: ProfileSystemDependencies {
        let storagePaths: StoragePaths
        let windowSystemModel: WindowSystemModel
      }
      let container = Container(
        storagePaths: rootStoragePaths,
        windowSystemModel: windowDataStore.model,
      )
      return Factory<ProfileSystem>.makeDefaultInstance(dependencies: container)
    }()

    let windowManager = {
      @MainActor
      struct Container: WindowManagerDependencies {
        let profileSystem: ProfileSystem
        let windowSystemModel: WindowSystemModel
      }
      let container = Container(
        profileSystem: profileSystem,
        windowSystemModel: windowDataStore.model,
      )
      return Factory<WindowManager>.makeDefaultInstance(dependencies: container)
    }()

    // Store exported modules:

    self.profileSystem = profileSystem
    self.windowDataStore = windowDataStore
    self.windowManager = windowManager
  }

  let profileSystem: ProfileSystem
  let windowDataStore: WindowDataStore
  let windowManager: WindowManager
}
