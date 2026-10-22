import Foundation
import SparrowSuggest

public struct AddressBarCompletion: Sendable, Equatable {
  public enum Kind: Sendable, Equatable {
    case navigation
    case search
    case chat
  }

  public let kind: Kind
  public let url: URL
  public let typed: Bool
}

extension AddressBarCompletion {
  init?(_ result: SuggestQueryResult) {
    guard let url = result.url else { return nil }

    let kind: Kind =
      switch result.kind {
      case .navigation:
        .navigation
      case .search:
        .search
      case .chat:
        .chat
      }

    self.init(
      kind: kind,
      url: url,
      typed: result.representsInput,
    )
  }
}