import Foundation

public enum ImageSource: Sendable, Equatable, Hashable {
  case file(URL)
  case resource(named: String, withExtension: String)
  case symbol(SymbolSource)
  case custom(kind: String, id: String)
}

extension ImageSource {
  public var fileURL: URL? {
    switch self {
    case .file(let url):
      url
    case let .resource(name, ext):
      Bundle.main.url(forResource: name, withExtension: ext)
    case .symbol, .custom:
      nil
    }
  }
}