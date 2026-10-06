#if os(Windows)
import UWP
#endif

@MainActor
public struct Keybinding: Sendable, Equatable {
  #if os(macOS)
  public init(keyEquivalent: String, modifiers: Keystroke.ModifierFlags) {
    self.keyEquivalent = keyEquivalent
    self.modifiers = modifiers
  }
  #elseif os(Windows)
  public init(virtualKey: VirtualKey, modifiers: Keystroke.ModifierFlags) {
    self.virtualKey = virtualKey
    self.modifiers = modifiers
  }
  #endif

  #if os(macOS)
  public let keyEquivalent: String
  #elseif os(Windows)
  public let virtualKey: VirtualKey
  #endif
  public let modifiers: Keystroke.ModifierFlags
}

extension Keybinding: @MainActor CustomStringConvertible {
  public var description: String {
    #if os(macOS)
    modifiersGlyphs + keyEquivalent.uppercased()
    #elseif os(Windows)
    modifiersGlyphs + virtualKey.description
    #endif
  }

  private var modifiersGlyphs: String {
    var s = ""

    #if os(macOS)
    if modifiers.contains(.control) { s += "⌃" }
    if modifiers.contains(.option)  { s += "⌥" }
    if modifiers.contains(.shift)   { s += "⇧" }
    if modifiers.contains(.command) { s += "⌘" }
    #elseif os(Windows)
    if modifiers.contains(.control) { s += "Ctrl+" }
    if modifiers.contains(.menu)    { s += "Alt+" }
    if modifiers.contains(.shift)   { s += "Shift+" }
    #endif

    return s
  }
}

#if os(Windows)
extension Keybinding {
  public var virtualKeyModifiers: VirtualKeyModifiers {
    .init(modifiers)
  }
}
#endif
