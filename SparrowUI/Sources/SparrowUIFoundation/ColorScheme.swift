public enum ColorScheme: String, Sendable, Equatable {
  case light
  case dark
}

#if os(macOS)
import AppKit

extension ColorScheme {
  public static func from(_ appearance: NSAppearance) -> ColorScheme {
    appearance.bestMatch(from: [.darkAqua]) == .darkAqua ? .dark : .light
  }
}

#elseif os(Windows)
import WinUI

extension ColorScheme {
  public static func from(_ theme: ElementTheme) -> ColorScheme {
    switch theme {
    case .dark:
      .dark
    default:
      .light
    }
  }
}
#endif