import Foundation
import SparrowToolbelt

@MainActor
public protocol NetworkService {
  func load(url: URL) -> NetworkRequest
}

public protocol NetworkServiceProviding {
  @MainActor
  var networkService: NetworkService { get }
}

public typealias NetworkServiceDependencies
  = Any

extension Factory where Interface == NetworkService {
  public static func makeDefaultInstance(dependencies: NetworkServiceDependencies) -> NetworkService {
    DefaultNetworkService(dependencies: dependencies)
  }
}

final class DefaultNetworkService: NetworkService {
  init(dependencies: NetworkServiceDependencies) {
    self.dependencies = dependencies
  }

  func load(url: URL) -> NetworkRequest {
    print(">>> load url: \(url)")
    return DefaultNetworkRequest(url: url)
  }

  private let dependencies: NetworkServiceDependencies
}