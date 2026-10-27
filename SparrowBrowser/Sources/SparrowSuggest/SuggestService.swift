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
  = MergedSuggestQueryDependencies

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
    MergedSuggestQuery(dependencies: dependencies, input: input)
  }

  private let dependencies: SuggestServiceDependencies
}