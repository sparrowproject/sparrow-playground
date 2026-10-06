import Foundation

public struct WebContentStoragePartition: Sendable, Equatable {
  public enum Kind: Sendable, Equatable {
    /// Persisted across sessions.
    case persistent

    /// Kept around for the lifecycle of the `WebContentFactory`.
    case incognito
  }

  public init(identifier: UUID, kind: Kind) {
    self.identifier = identifier
    self.kind = kind
  }

  public let identifier: UUID
  public let kind: Kind
}