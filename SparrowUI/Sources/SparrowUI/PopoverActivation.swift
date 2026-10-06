public struct PopoverActivation: OptionSet, Sendable, Equatable {
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public let rawValue: Int

  public static let pointerPress = PopoverActivation(rawValue: 1 << 0)
  public static let pointerLongPress = PopoverActivation(rawValue: 1 << 1)
  public static let pointerContextPress = PopoverActivation(rawValue: 1 << 2)
  public static let pointerLinger = PopoverActivation(rawValue: 1 << 3)
}