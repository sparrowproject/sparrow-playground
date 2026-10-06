import Foundation
import SparrowNetwork
import SparrowToolbelt

@MainActor
public protocol SuggestService {
  func queryCompletions(for input: String) -> SuggestQuery
}

public protocol SuggestServiceProviding {
  @MainActor
  var suggestService: SuggestService { get }
}

public typealias SuggestServiceDependencies
  = NetworkServiceProviding

extension Factory where Interface == SuggestService {
  public static func makeDefaultInstance(dependencies: SuggestServiceDependencies) -> SuggestService {
    DefaultSuggestService(dependencies: dependencies)
  }
}

final class DefaultSuggestService: SuggestService {
  init(dependencies: SuggestServiceDependencies) {
    self.dependencies = dependencies
  }

  func queryCompletions(for input: String) -> SuggestQuery {
    var components = URLComponents(
      string: "https://suggestqueries.google.com/complete/search"
    )!
    components.queryItems = [
      URLQueryItem(name: "client", value: "firefox"),
      URLQueryItem(name: "q", value: input)
    ]

    let networkRequest = dependencies.networkService.load(url: components.url!)

    return DefaultSuggestQuery(input: input, networkRequest: networkRequest)
  }

  private let dependencies: SuggestServiceDependencies
}