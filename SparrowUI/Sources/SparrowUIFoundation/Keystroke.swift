#if os(macOS)
import AppKit
#elseif os(Windows)
import UWP
import WinSDK
#endif

public struct Keystroke: Sendable, Hashable, Equatable {
  #if os(macOS)
  public init(keyCode: UInt16) {
    self.keyCode = keyCode
  }
  public let keyCode: UInt16
  #elseif os(Windows)
  public init(virtualKey: VirtualKey) {
    self.virtualKey = virtualKey
  }
  public let virtualKey: VirtualKey
  #endif
}

extension Keystroke {
  #if os(macOS)
  public typealias ModifierFlags = NSEvent.ModifierFlags
  #elseif os(Windows)
  public struct ModifierFlags: OptionSet, Sendable, Equatable {
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public init(_ modifiers: VirtualKeyModifiers) {
      self.init(rawValue: modifiers.rawValue)
    }

    public let rawValue: Int32

    public static let control = Self(.control)
    public static let shift = Self(.shift)
    public static let menu = Self(.menu)
    public static let windows = Self(.windows)

    public static let alt = menu
  }

  #endif
}

#if os(Windows)
extension VirtualKeyModifiers {
  public init(_ modifiers: Keystroke.ModifierFlags) {
    self.init(rawValue: modifiers.rawValue)
  }
}

extension Keystroke.ModifierFlags {
  public static var current: Self {
    var modifiers = Keystroke.ModifierFlags()
    if (Int(GetKeyState(VK_CONTROL)) & 0x8000) != 0 {
      modifiers.insert(.control)
    }
    if (Int(GetKeyState(VK_SHIFT)) & 0x8000) != 0 {
      modifiers.insert(.shift)
    }
    if (Int(GetKeyState(VK_MENU)) & 0x8000) != 0 {
      modifiers.insert(.alt)
    }
    return modifiers
  }
}
#endif