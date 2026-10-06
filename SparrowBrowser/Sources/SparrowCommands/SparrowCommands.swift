import SparrowUIFoundation

#if os(macOS)
import AppKit
#endif

@MainActor
public enum SparrowCommands {
  public static var quit: SparrowCommand { .init(id: .quit, title: "Quit", keybinding: .quit) }

  public static var newTab: SparrowCommand { .init(id: .newTab, title: "New tab", keybinding: .newTab) }
  public static var newWindow: SparrowCommand { .init(id: .newWindow, title: "New window", keybinding: .newWindow) }
  public static var newIncognitoWindow: SparrowCommand { .init(id: .newIncognitoWindow, title: "New incognito window", keybinding: .newIncognitoWindow) }

  public static var openLocation: SparrowCommand { .init(id: .openLocation, title: "Open Location...", keybinding: .openLocation) }

  // TODO: Enable these specifically on Windows.
  // public static var cut: SparrowCommand { .init(id: .cut, title: "Cut", keybinding: .cut) }
  // public static var copy: SparrowCommand { .init(id: .copy, title: "Copy", keybinding: .copy) }
  // public static var paste: SparrowCommand { .init(id: .paste, title: "Paste", keybinding: .paste) }

  public static var reloadTab: SparrowCommand { .init(id: .reloadTab, title: "Reload", keybinding: .reloadTab) }
  public static var duplicateTab: SparrowCommand { .init(id: .duplicateTab, title: "Duplicate") }
  public static var pinTab: SparrowCommand { .init(id: .pinTab, title: "Pin") }
  public static var unpinTab: SparrowCommand { .init(id: .unpinTab, title: "Unpin") }
  public static var muteTab: SparrowCommand { .init(id: .muteTab, title: "Mute") }
  public static var unmuteTab: SparrowCommand { .init(id: .unmuteTab, title: "Unmute") }
  public static var toggleTabMode: SparrowCommand { .init(id: .toggleTabMode, title: "Toggle tab style") }
  public static var closeTab: SparrowCommand { .init(id: .closeTab, title: "Close", keybinding: .closeTab) }
  public static var closeOtherTabs: SparrowCommand { .init(id: .closeOtherTabs, title: "Close other tabs") }
  public static var closeWindow: SparrowCommand { .init(id: .closeWindow, title: "Close window", keybinding: .closeWindow) }
  public static var goBack: SparrowCommand { .init(id: .goBack, title: "Back", keybinding: .goBack) }
  public static var goForward: SparrowCommand { .init(id: .goForward, title: "Forward", keybinding: .goForward) }

  #if os(macOS)
  public static var goBackAlt: SparrowCommand { .init(id: .goBack, title: "Back", keybinding: .goBackAlt) }
  public static var goForwardAlt: SparrowCommand { .init(id: .goForward, title: "Forward", keybinding: .goForwardAlt) }
  #endif

  public static func newTabAfter(forTopTabs: Bool) -> SparrowCommand {
    .init(id: .newTabAfter, title: forTopTabs ? "New tab to the right" : "New tab below")
  }
  public static func closeTabsAfter(forTopTabs: Bool) -> SparrowCommand {
    .init(id: .closeTabsAfter, title: forTopTabs ? "Close tabs to the right" : "Close tabs below")
  }

  public static var selectNextTab: SparrowCommand { .init(id: .selectNextTab, title: "Select next tab", keybinding: .selectNextTab) }
  public static var selectPreviousTab: SparrowCommand { .init(id: .selectPreviousTab, title: "Select previous tab", keybinding: .selectPreviousTab) }

  public static func selectTabAt(index: Int) -> SparrowCommand {
    .init(id: .selectTabAt(index: index), title: "", keybinding: .selectTabAt(index: index))
  }
}

extension Keybinding {
  fileprivate static var quit: Self {
    #if os(macOS)
    .init(keyEquivalent: "q", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .q, modifiers: [.control])
    #endif
  }

  fileprivate static var newTab: Self {
    #if os(macOS)
    .init(keyEquivalent: "t", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .t, modifiers: [.control])
    #endif
  }

  fileprivate static var newWindow: Self {
    #if os(macOS)
    .init(keyEquivalent: "n", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .n, modifiers: [.control])
    #endif
  }

  fileprivate static var newIncognitoWindow: Self {
    #if os(macOS)
    .init(keyEquivalent: "n", modifiers: [.command, .shift])
    #elseif os(Windows)
    .init(virtualKey: .n, modifiers: [.control, .shift])
    #endif
  }

  fileprivate static var downloads: Self {
    #if os(macOS)
    .init(keyEquivalent: "l", modifiers: [.command, .option])
    #elseif os(Windows)
    .init(virtualKey: .j, modifiers: [.control])
    #endif
  }

  fileprivate static var openLocation: Self {
    #if os(macOS)
    .init(keyEquivalent: "l", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .l, modifiers: [.control])
    #endif
  }

  // fileprivate static var cut: Self {
  //   #if os(macOS)
  //   .init(keyEquivalent: "x", modifiers: [.command])
  //   #elseif os(Windows)
  //   .init(virtualKey: .x, modifiers: [.control])
  //   #endif
  // }

  // fileprivate static var copy: Self {
  //   #if os(macOS)
  //   .init(keyEquivalent: "c", modifiers: [.command])
  //   #elseif os(Windows)
  //   .init(virtualKey: .c, modifiers: [.control])
  //   #endif
  // }

  // fileprivate static var paste: Self {
  //   #if os(macOS)
  //   .init(keyEquivalent: "v", modifiers: [.command])
  //   #elseif os(Windows)
  //   .init(virtualKey: .v, modifiers: [.control])
  //   #endif
  // }

  fileprivate static var print: Self {
    #if os(macOS)
    .init(keyEquivalent: "p", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .p, modifiers: [.control])
    #endif
  }

  fileprivate static var settings: Self? {
    #if os(macOS)
    .init(keyEquivalent: ",", modifiers: [.command])
    #elseif os(Windows)
    nil
    #endif
  }

  fileprivate static var find: Self {
    #if os(macOS)
    .init(keyEquivalent: "f", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .f, modifiers: [.control])
    #endif
  }

  fileprivate static var cut: Self {
    #if os(macOS)
    .init(keyEquivalent: "x", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .x, modifiers: [.control])
    #endif
  }

  fileprivate static var copy: Self {
    #if os(macOS)
    .init(keyEquivalent: "c", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .c, modifiers: [.control])
    #endif
  }

  fileprivate static var paste: Self {
    #if os(macOS)
    .init(keyEquivalent: "v", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .v, modifiers: [.control])
    #endif
  }

  fileprivate static var reloadTab: Self {
    #if os(macOS)
    .init(keyEquivalent: "r", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .r, modifiers: [.control])
    #endif
  }

  fileprivate static var closeTab: Self {
    #if os(macOS)
    .init(keyEquivalent: "w", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .w, modifiers: [.control])
    #endif
  }

  fileprivate static var closeWindow: Self {
    #if os(macOS)
    .init(keyEquivalent: "w", modifiers: [.command, .shift])
    #elseif os(Windows)
    .init(virtualKey: .w, modifiers: [.control, .shift])
    #endif
  }

  fileprivate static var goBack: Self {
    #if os(macOS)
    .init(keyEquivalent: "[", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .left, modifiers: [.alt])
    #endif
  }

  fileprivate static var goForward: Self {
    #if os(macOS)
    .init(keyEquivalent: "]", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .right, modifiers: [.alt])
    #endif
  }

  #if os(macOS)
  fileprivate static var goBackAlt: Self {
    .init(keyEquivalent: String(UnicodeScalar(NSLeftArrowFunctionKey)!), modifiers: [.command])
  }

  fileprivate static var goForwardAlt: Self {
    .init(keyEquivalent: String(UnicodeScalar(NSRightArrowFunctionKey)!), modifiers: [.command])
  }
  #endif

  fileprivate static var selectNextTab: Self {
    #if os(macOS)
    .init(keyEquivalent: "\t", modifiers: [.control])
    #elseif os(Windows)
    .init(virtualKey: .tab, modifiers: [.control])
    #endif
  }

  fileprivate static var selectPreviousTab: Self {
    #if os(macOS)
    .init(keyEquivalent: "\t", modifiers: [.control, .shift])
    #elseif os(Windows)
    .init(virtualKey: .tab, modifiers: [.control, .shift])
    #endif
  }

  fileprivate static func selectTabAt(index: Int) -> Self {
    #if os(macOS)
    .init(keyEquivalent: "\(index)", modifiers: [.control])
    #elseif os(Windows)
    .init(virtualKey: .numberKey(for: index), modifiers: [.control])
    #endif
  }
}
