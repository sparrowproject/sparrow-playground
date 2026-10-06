#if os(Windows)
import WinSDK

// MARK: Window Hooks

@MainActor
public enum WindowProcHookResult: Sendable, Equatable {
  case forwardToOriginal
  case forwardToDefault
  case result(LRESULT)
}

public typealias WindowProcHook = @MainActor (HWND, UINT, WPARAM, LPARAM) -> WindowProcHookResult

@MainActor
public func hookWindowProc(hwnd: HWND, hook: @escaping WindowProcHook) {
  guard windowProcHooks[hwnd] == nil else {
    windowProcHooks[hwnd]?.hook = hook
    // assertionFailure("Window Proc is already hooked!")
    return
  }

  // SetWindowLongPtr can validly return zero, so clear and inspect
  // the thread's last-error value.
  SetLastError(0)

  let newProcValue = unsafeBitCast(
    hookedWndProc,
    to: LONG_PTR.self
  )

  let originalProcValue = SetWindowLongPtrW(
    hwnd,
    GWLP_WNDPROC,
    newProcValue
  )

  if originalProcValue == 0 {
    let error = GetLastError()
    if error != 0 {
      assertionFailure("Failed to hook window proc, error: \(error)")
      return
    }
  }

  let originalProc = unsafeBitCast(
    originalProcValue,
    to: WNDPROC.self
  )

  windowProcHooks[hwnd] = .init(hook: hook, originalProc: originalProc)
}

@MainActor
public func unhookWindowProc(hwnd: HWND) {
  guard let state = windowProcHooks[hwnd] else {
    assertionFailure("Window proc not hooked!")
    return
  }

  let originalProcValue = unsafeBitCast(
    state.originalProc,
    to: LONG_PTR.self
  )

  SetLastError(0)

  let result = SetWindowLongPtrW(
    hwnd,
    GWLP_WNDPROC,
    originalProcValue
  )

  if result == 0 {
    let error = GetLastError()
    if error != 0 {
      assertionFailure("Failed to reset window proc, error: \(error)")
      return
    }
  }

  windowProcHooks.removeValue(forKey: hwnd)
}

@MainActor
private struct HookState {
  var hook: WindowProcHook
  let originalProc: WNDPROC
}

@MainActor
private var windowProcHooks = [HWND: HookState]()

@MainActor
private let hookedWndProc: WNDPROC = { (hwnd: HWND!, message: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT in
  guard let state = windowProcHooks[hwnd] else {
    assertionFailure("HookedWndProc invoked for unknown window!")
    return 0
  }

  let result: LRESULT =
    switch state.hook(hwnd, message, wParam, lParam) {
    case .result(let result):
      result

    case .forwardToOriginal:
      CallWindowProcW(state.originalProc, hwnd, message, wParam, lParam)

    case .forwardToDefault:
      DefWindowProcW(hwnd, message, wParam, lParam)
    }

  if message == UINT(WM_NCDESTROY) {
    windowProcHooks.removeValue(forKey: hwnd)    
  }

  return result
}

// MARK: Window Creation

public func createWindow(
  owner: HWND?,
  style: DWORD,
  exStyle: DWORD,
) -> HWND? {
  // Ensure the window class is registered.
  _ = registerWindowClass()

  let instance = GetModuleHandleW(nil)

  return windowClassName.withUnsafeBufferPointer { className in
    CreateWindowExW(
      exStyle,
      className.baseAddress,
      nil,
      style,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      owner,
      nil,
      instance,
      nil
    )
  }
}

private let windowClassName = Array("SparrowWindowClass\0".utf16)

private let defaultWindowProc: WNDPROC = { hwnd, message, wParam, lParam in
  return DefWindowProcW(hwnd, message, wParam, lParam)
}

private func registerWindowClass() -> ATOM {
  let instance = GetModuleHandleW(nil)

  var windowClass = WNDCLASSEXW()
  windowClass.cbSize = UINT(MemoryLayout<WNDCLASSEXW>.size)
  windowClass.style = UINT(CS_HREDRAW | CS_VREDRAW)
  windowClass.lpfnWndProc = defaultWindowProc
  windowClass.cbClsExtra = 0
  windowClass.cbWndExtra = 0
  windowClass.hInstance = instance
  windowClass.hIcon = nil
  windowClass.hCursor = nil // LoadCursorW(nil, IDC_ARROW)
  windowClass.hbrBackground = nil
  windowClass.lpszMenuName = nil
  windowClass.hIconSm = nil

  return windowClassName.withUnsafeBufferPointer { className in
    windowClass.lpszClassName = className.baseAddress
    return RegisterClassExW(&windowClass)
  }
}

// MARK: Window Enumeration

public func childWindows(of parent: HWND) -> [HWND] {
  final class WindowList {
    var windows: [HWND] = []
  }

  let list = WindowList()
  let retained = Unmanaged.passRetained(list)

  defer {
    retained.release()
  }

  EnumChildWindows(parent, { (hwnd: HWND!, lParam: LPARAM) in
    let list = Unmanaged<WindowList>
      .fromOpaque(UnsafeRawPointer(bitPattern: Int(lParam))!)
      .takeUnretainedValue()
    list.windows.append(hwnd)
    return WindowsBool(true)
  }, LPARAM(Int(bitPattern: retained.toOpaque())))

  return list.windows
}

// MARK: Class name

public func className(of hwnd: HWND) -> String? {
  var buffer = [WCHAR](repeating: 0, count: 256)

  let length = GetClassNameW(
    hwnd,
    &buffer,
    Int32(buffer.count)
  )

  guard length > 0 else {
    return nil
  }

  return String(utf16CodeUnits: buffer, count: Int(length))
}

#endif