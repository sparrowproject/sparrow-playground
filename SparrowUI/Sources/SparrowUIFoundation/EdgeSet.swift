import Foundation

public struct EdgeSet: OptionSet, Sendable {
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public let rawValue: Int

  public static let top = EdgeSet(rawValue: 1 << 0)
  public static let bottom = EdgeSet(rawValue: 1 << 1)
  public static let leading = EdgeSet(rawValue: 1 << 2)
  public static let trailing = EdgeSet(rawValue: 1 << 3)

  public static let horizontal: EdgeSet = [.leading, .trailing]
  public static let vertical: EdgeSet = [.top, .bottom]

  public static let all: EdgeSet = [.top, .bottom, .leading, .trailing]
}
