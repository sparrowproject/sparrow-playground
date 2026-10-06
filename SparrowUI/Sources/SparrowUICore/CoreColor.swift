import Foundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import UWP
#endif

public struct CoreColor: Sendable, Equatable {
  #if os(macOS)

  init(_ value: CGColor) {
    self.value = value
  }

  public let value: CGColor

  #elseif os(Windows)

  init(_ value: UWP.Color) {
    self.value = value
  }

  public let value: UWP.Color

  #endif
}

extension CoreColor {
  public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
    self.init(.init(red: red, green: green, blue: blue, alpha: alpha))
  }

  public init(gray: CGFloat, alpha: CGFloat = 1) {
    self.init(.init(gray: gray, alpha: alpha))
  }

  public init(hex: UInt32, alpha: CGFloat = 1) {
    // 0xRRGGBB
    let red = CGFloat(hex >> 16 & 0xFF) / 0xFF
    let green = CGFloat(hex >> 8 & 0xFF) / 0xFF
    let blue = CGFloat(hex & 0xFF) / 0xFF
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension CoreColor {
  public func withAlpha(_ alpha: CGFloat) -> CoreColor {
    .init(value.copy(alpha: alpha)!)
  }

  public func opacity(_ opacity: CGFloat) -> CoreColor {
    .init(value.copy(alpha: value.alpha * opacity)!)
  }
}

extension CoreColor {
  public static let clear = Self(red: 0, green: 0, blue: 0, alpha: 0)
  public static let white = Self(red: 1, green: 1, blue: 1, alpha: 1)
  public static let black = Self(red: 0, green: 0, blue: 0, alpha: 1)

  public static let red = Self(red: 1, green: 0, blue: 0, alpha: 1)
  public static let green = Self(red: 0, green: 1, blue: 0, alpha: 1)
  public static let blue = Self(red: 0, green: 0, blue: 1, alpha: 1)
  public static let orange = Self(hex: 0xFFA500)
  public static let magenta = Self(red: 1, green: 0, blue: 1, alpha: 1)
  public static let cyan = Self(red: 0, green: 1, blue: 1, alpha: 1)
  public static let yellow = Self(red: 1, green: 1, blue: 0, alpha: 1)
}

#if os(Windows)
extension UWP.Color {
  fileprivate init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    self.init(
      a: UInt8(alpha * 255),
      r: UInt8(red * 255),
      g: UInt8(green * 255),
      b: UInt8(blue * 255),
    )
  }

  fileprivate init(gray: CGFloat, alpha: CGFloat) {
    self.init(
      red: gray,
      green: gray,
      blue: gray,
      alpha: alpha,
    )
  }

  fileprivate func copy(alpha: CGFloat) -> UWP.Color? {
    .init(
      a: UInt8(alpha * 255),
      r: r,
      g: g,
      b: b,
    )
  }

  fileprivate var alpha: CGFloat {
    CGFloat(a) / 255
  }
}
#endif
