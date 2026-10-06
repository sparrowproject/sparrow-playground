#if os(Windows)
import Foundation
import OrderedCollections
import WinSDK

@MainActor
public final class MouseMonitor: NSObject {
  public init(handler: @escaping (DisplayPoint) -> Void) {
    self.handler = handler
  }

  @MainActor deinit {
    stop()
  }

  public func start() {
    Self.monitors.append(self)
  }

  public func stop() {
    Self.monitors.remove(self)
  }

  static func notifyMonitors(point: POINT) {
    for monitor in monitors {
      monitor.handler(.init(x: point.x, y: point.y))
    }
  }

  private let handler: (DisplayPoint) -> Void

  private static var monitors = OrderedSet<MouseMonitor>() {
    didSet {
      if monitors.isEmpty {
        if !oldValue.isEmpty {
          removeHook()
        }
      } else {
        if oldValue.isEmpty {
          insertHook()
        }
      }
    }
  }

  private static var hook: HHOOK?

  private static func insertHook() {
    guard hook == nil else { return }

    hook = SetWindowsHookExW(WH_MOUSE_LL, hookFunc, nil, 0)
    if hook == nil {
      print(">>> SetWindowsHookExW failed: \(GetLastError())")
    }
  }

  private static func removeHook() {
    if let hook {
      UnhookWindowsHookEx(hook)
      Self.hook = nil
    }
  }
}

private let hookFunc: HOOKPROC = { (nCode: Int32, wParam: WPARAM, lParam: LPARAM) in
  if nCode >= 0, wParam == WPARAM(WM_MOUSEMOVE) {
    let info = UnsafePointer<MSLLHOOKSTRUCT>(
      bitPattern: UInt(lParam)
    )!.pointee

    MainActor.assumeIsolated {
      MouseMonitor.notifyMonitors(point: info.pt)
    }
  }

  return CallNextHookEx(
    nil,
    nCode,
    wParam,
    lParam
  )
}

#endif