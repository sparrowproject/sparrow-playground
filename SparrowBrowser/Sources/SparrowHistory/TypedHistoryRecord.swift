public struct TypedHistoryRecord: Sendable, Equatable, Codable {
  public enum Kind: String, Sendable, Equatable, Codable {
    case navigation
    case search
    case chat
  }

  public init(kind: Kind, value: String) {
    self.kind = kind
    self.value = value
  }

  public let kind: Kind
  public let value: String
}