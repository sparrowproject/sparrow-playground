import Foundation
import SparrowToolbelt

public enum SuggestQueryResult: Sendable, Equatable {
  case search(String)
  case navigation(URL, displayString: String)
  case chat(String)
}

extension SuggestQueryResult {
  public var displayString: String {
    switch self {
    case .search(let string), .chat(let string):
      string
    case .navigation(_, let string):
      string
    }
  }

  public var url: URL? {
    switch self {
    case .search(let string):
      .googleSearchURL(for: string)
    case .chat(let string):
      .chatGPTURL(for: string)
    case .navigation(let url, _):
      url
    }
  }

  public var isSearch: Bool {
    switch self {
    case .search:
      true
    default:
      false
    }
  }

  public var isChat: Bool {
    switch self {
    case .chat:
      true
    default:
      false
    }
  }
}