import SparrowUIFoundation

@MainActor
public enum StandardSymbols {
  public static var back: SymbolSource {
    #if os(macOS)
    .init(systemName: "chevron.left", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e76b}", size: 12) // ChevronLeft
    #endif
  }

  public static var forward: SymbolSource {
    #if os(macOS)
    .init(systemName: "chevron.right", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e76c}", size: 12) // ChevronRight
    #endif
  }

  public static var reload: SymbolSource {
    #if os(macOS)
    .init(systemName: "arrow.clockwise", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e72c}", size: 12) // Refresh
    #endif
  }

  public static var stop: SymbolSource {
    #if os(macOS)
    .init(systemName: "xmark", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e711}", size: 12) // Cancel
    #endif
  }

  public static var menu: SymbolSource {
    #if os(macOS)
    .init(systemName: "line.3.horizontal", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e700}", size: 12) // GlobalNavButton
    #endif
  }

  public static var newTab: SymbolSource {
    #if os(macOS)
    .init(systemName: "plus", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e710}", size: 12) // Add
    #endif
  }

  public static var grid: SymbolSource {
    #if os(macOS)
    .init(systemName: "square.grid.2x2", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e8a9}", size: 12) // ViewAll
    #endif
  }
}