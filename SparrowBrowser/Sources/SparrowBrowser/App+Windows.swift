#if os(Windows)
import SparrowCommands
import SparrowUIFoundation
import UWP
import WinSDK
import WinUI

extension App {
  static let acceleratorCommands = [
    SparrowCommands.newTab,
    SparrowCommands.newWindow,
    SparrowCommands.newIncognitoWindow,
    SparrowCommands.closeTab,
    SparrowCommands.closeWindow,
    SparrowCommands.openLocation,
    SparrowCommands.selectNextTab,
    SparrowCommands.selectPreviousTab,
    SparrowCommands.selectTabAt(index: 0),
    SparrowCommands.selectTabAt(index: 1),
    SparrowCommands.selectTabAt(index: 2),
    SparrowCommands.selectTabAt(index: 3),
    SparrowCommands.selectTabAt(index: 4),
    SparrowCommands.selectTabAt(index: 5),
    SparrowCommands.selectTabAt(index: 6),
    SparrowCommands.selectTabAt(index: 7),
    SparrowCommands.selectTabAt(index: 8),
    SparrowCommands.selectTabAt(index: 9),
  ]

  @MainActor
  func setUpKeyboardAccelerators() {
    _hook = SetWindowsHookExW(
      WH_GETMESSAGE,
      _hookProc,
      HINSTANCE(bitPattern: 0),
      GetCurrentThreadId(),
    )
  }

  func handleKeystroke(_ keystroke: Keystroke, modifiers: Keystroke.ModifierFlags) -> Bool {
    // TODO: Use a lookup table to improve performance.
    // TODO: Figure out how to allow for keybindings being taken over by the web page.

    for command in Self.acceleratorCommands {
      if let keybinding = command.keybinding, keybinding.virtualKey == keystroke.virtualKey, keybinding.modifiers == modifiers {
        appContainer.windowManager.handleCommand(command.id)
        return true
      }
    }

    return false
  }

  static var instance: App {
    (Application.current as! App)
  }
}

@MainActor
private var _hook = HHOOK(bitPattern: 0)

@MainActor
private let _hookProc: HOOKPROC = { (code: Int32, wParam: WPARAM, lParam: LPARAM) -> LRESULT in
  if code >= 0 {
    let ptr = UnsafeMutablePointer<MSG>(
      bitPattern: UInt(lParam)
    )!
    var msg = ptr.pointee

    switch Int32(msg.message) {
    case WM_KEYDOWN, WM_SYSKEYDOWN: // , WM_KEYUP, WM_SYSKEYUP:
      let virtualKey = VirtualKey(rawValue: Int32(msg.wParam))

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
      if App.instance.handleKeystroke(.init(virtualKey: virtualKey), modifiers: modifiers) {
        print(">>> --- intercepted key event: \(virtualKey), modifiers: \(modifiers)")
        msg.message = UINT(WM_NULL)
      }
    default:
      break
    }
  }

  return CallNextHookEx(_hook, code, wParam, lParam)
}

#endif