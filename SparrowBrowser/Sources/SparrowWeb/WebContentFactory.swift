import SparrowStorageBase
import SparrowToolbelt

@MainActor
public protocol WebContentFactory {
  func createWebContent(initializationParams: WebContentInitializationParams?) -> WebContent
}

public protocol WebContentFactoryProviding {
  @MainActor
  var webContentFactory: WebContentFactory { get }
}

public typealias WebContentFactoryDependencies
  = StoragePathsProviding
  & WebHistoryProviding

extension Factory where Interface == WebContentFactory {
  public static func makeDefaultInstance(
    dependencies: WebContentFactoryDependencies,
    partition: WebContentStoragePartition,
  ) -> WebContentFactory {
    #if os(macOS)
    WebContentFactoryWK(dependencies: dependencies, partition: partition)
    #elseif os(Windows)
    WebContentFactoryWV2(dependencies: dependencies, partition: partition)
    #endif
  }
}
