import Foundation
import SparrowToolbelt

public struct SuggestQueryResult: Sendable, Equatable {
  public enum Kind: Sendable, Equatable {
    case navigation(URL)
    case search
    case chat
  }

  public init(
    kind: Kind,
    value: String,
    representsInput: Bool,
  ) {
    self.kind = kind
    self.value = value
    self.representsInput = representsInput
  }

  public let kind: Kind
  public let value: String

  /// If true, then this value represents passing the user input through unmodified.
  public let representsInput: Bool
}

extension SuggestQueryResult {
  public var url: URL? {
    switch kind {
    case .navigation(let url):
      url
    case .search:
      .googleSearchURL(for: value)
    case .chat:
      .chatGPTURL(for: value)
    }
  }

  public var isSearch: Bool {
    switch kind {
    case .search:
      true
    default:
      false
    }
  }

  public var isChat: Bool {
    switch kind {
    case .chat:
      true
    default:
      false
    }
  }
}