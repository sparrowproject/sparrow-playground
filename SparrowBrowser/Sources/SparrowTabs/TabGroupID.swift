import Foundation
import Tagged

public struct TabGroupID: Sendable, Equatable, Hashable {
  public struct Kind: Sendable, RawRepresentable, Equatable, Hashable {
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
    public let rawValue: String
  }

  public init(kind: Kind, components: [String]) {
    rawValue = "\(kind.rawValue)--\(components.joined(separator: "--"))"
  }

  public let rawValue: String

  public var kind: Kind {
    .init(rawValue: String(rawValue.split(separator: "--", maxSplits: 1)[0]))
  }

  public var components: [String] {
    rawValue.split(separator: "--")[1...].map { String($0) }
  }
}

extension TabGroupID: RawRepresentable {
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension TabGroupID {
  public static let invalid = TabGroupID(kind: .init(rawValue: ""), components: [])

  public var nilIfInvalid: TabGroupID? {
    if self == .invalid {
      nil
    } else {
      self
    }
  }
}

extension TabGroupID: Codable {}

extension TabGroupID: Identifiable {
  public var id: String { rawValue }
}