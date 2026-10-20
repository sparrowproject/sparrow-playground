import Foundation

public enum SuggestQueryResult: Sendable, Equatable {
  case search(String)
  case navigation(URL)
}

extension SuggestQueryResult {
  public var displayString: String {
    switch self {
    case .search(let string):
      string
    case .navigation(let url):
      url.absoluteString // TODO: Trim off the scheme, etc.
    }
  }
}