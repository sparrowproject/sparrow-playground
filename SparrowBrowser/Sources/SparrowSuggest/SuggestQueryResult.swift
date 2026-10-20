import Foundation
import SparrowToolbelt

public enum SuggestQueryResult: Sendable, Equatable {
  case search(String)
  case navigation(URL, displayString: String)
}

extension SuggestQueryResult {
  public var displayString: String {
    switch self {
    case .search(let string):
      string
    case .navigation(_, let string):
      string
    }
  }

  public var url: URL? {
    switch self {
    case .search(let string):
      .googleSearchURL(for: string)    
    case .navigation(let url, _):
      url
    }
  }
}