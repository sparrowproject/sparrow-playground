import SparrowDownloads
import SparrowStorageBase
import SparrowTabs
import SparrowToolbelt
import SparrowWeb

// TODO: Consider renaming this the TabStorageSystem.
@MainActor
public protocol StorageSystem: StorageComponent {
  func initialize() async
}

public protocol StorageSystemProviding {
  @MainActor
  var storageSystem: StorageSystem { get }
}

public typealias StorageSystemDependencies
  = DownloadsManagerProviding
  & SpaceStoreProviding
  & StoragePathsProviding
  & TabSystemProviding
  & WebHistoryProviding

extension Factory where Interface == StorageSystem {
  public static func makeDefaultInstance(dependencies: StorageSystemDependencies) -> StorageSystem {
    DefaultStorageSystem(dependencies: dependencies)
  }
}

final class DefaultStorageSystem: StorageSystem {
  init(dependencies: StorageSystemDependencies) {
    self.dependencies = dependencies
    tabStore = .init(dependencies: dependencies)
    tabGroupStore = .init(dependencies: dependencies)
    downloadInfoStore = .init(dependencies: dependencies)
  }

  func initialize() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        await self.initializeTabSystem()
      }
      group.addTask {
        await self.initializeDownloadInfoStore()
      }
      group.addTask {
        await self.initializeSpaceStore()
      }
      // Add other profile-scoped services here.
    }
  }

  func shutdown() -> ShutdownTask? {
    var tasks = [ShutdownTask]()

    if let task = tabStore.shutdown() {
      tasks.append(task)
    }
    if let task = tabGroupStore.shutdown() {
      tasks.append(task)
    }
    if let task = downloadInfoStore.shutdown() {
      tasks.append(task)
    }
    if let task = dependencies.spaceStore.shutdown() {
      tasks.append(task)
    }
    if let task = (dependencies.webHistory as? StorageComponent)?.shutdown() {
      tasks.append(task)
    }

    return tasks.isEmpty ? nil : tasks.joined()
  }

  private let dependencies: StorageSystemDependencies
  private let tabStore: TabStore
  private let tabGroupStore: TabGroupStore
  private let downloadInfoStore: DownloadInfoStore

  private func initializeTabSystem() async {
    await dependencies.tabSystem.initialize { tabSystemInitializer in
      await withTaskGroup(of: Void.self) { group in
        group.addTask { [tabStore] in
          await tabStore.readData(tabSystemInitializer: tabSystemInitializer)
        }
        group.addTask { [tabGroupStore] in
          await tabGroupStore.readData(tabSystemInitializer: tabSystemInitializer)
        }
      }
    }
    tabStore.setUpObservers()
    tabGroupStore.setUpObservers()
  }

  private func initializeDownloadInfoStore() async {
    await downloadInfoStore.initialize()
  }

  private func initializeSpaceStore() async {
    await dependencies.spaceStore.initialize()
  }
}