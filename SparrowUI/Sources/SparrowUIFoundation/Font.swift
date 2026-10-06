import Foundation

#if os(macOS)
import AppKit
#endif

public struct Font: Sendable {
  public enum Weight: Sendable {
    case thin
    case ultraLight
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
  }

  public enum Design: Sendable {
    case `default`
    case monospaced
    #if os(Windows)
    case symbol
    #endif
  }

  public static func system(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
    .init(size: size, weight: weight, design: design)
  }

  public let size: CGFloat
  public let weight: Font.Weight
  public let design: Font.Design
}

extension Font: Equatable {}

extension Font {
  public static let `default` = Font.system(size: 14)
}

extension Font.Weight {
  public var value: Int {
    switch self {
    case .thin:
      100
    case .ultraLight:
      200
    case .light:
      300
    case .regular:
      400
    case .medium:
      500
    case .semibold:
      600
    case .bold:
      700
    case .heavy:
      800
    case .black:
      900
    }
  }
}

#if os(macOS)
extension NSFont {
  public static func from(_ font: Font) -> NSFont {
    switch font.design {
    case .default:
      .systemFont(ofSize: font.size, weight: .from(font.weight))
    case .monospaced:
      .monospacedSystemFont(ofSize: font.size, weight: .from(font.weight))
    }
  }
}

extension NSFont.Weight {
  public static func from(_ weight: Font.Weight) -> NSFont.Weight {
    switch weight {
    case .thin:
      .thin
    case .ultraLight:
      .ultraLight
    case .light:
      .light
    case .regular:
      .regular
    case .medium:
      .medium
    case .semibold:
      .semibold
    case .bold:
      .bold
    case .heavy:
      .heavy
    case .black:
      .black
    }
  }
}
#endif

#if os(Windows)
extension Font {
  public var family: String {
    switch design {
    case .default:
      "Segoe UI"
    case .monospaced:
      "Cascadia Mono"
    case .symbol:
      "Segoe Fluent Icons"
    }
  }
}
#endif