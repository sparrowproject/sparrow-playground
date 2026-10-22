public struct TypedHistoryRecord: Sendable, Equatable {
  public enum Kind: Sendable, Equatable {
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