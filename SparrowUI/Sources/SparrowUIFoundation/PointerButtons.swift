public struct PointerButtons: OptionSet, Sendable, Equatable {
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public let rawValue: Int

  public static let left = PointerButtons(rawValue: 1 << 0)
  public static let middle = PointerButtons(rawValue: 1 << 1)
  public static let right = PointerButtons(rawValue: 1 << 2)
}