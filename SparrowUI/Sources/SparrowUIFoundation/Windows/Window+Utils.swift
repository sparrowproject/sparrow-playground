#if os(Windows)
import class UWP.Compositor
@_spi(WinRTInternal) import WinAppSDK
import WinUI
import WindowsFoundation
import WinSDK

extension Window {
  /// Configures the `Window` to render with transparency. This does not handle
  /// hit-testing. That has to be managed separately.
  public func enableTransparentBackdrop() {
    // This is the key API used to override the window background with a clear brush.
    // It uses the system compositor, not the WinAppSDK one!
    let supportsSystemBackdrop: __ABI_Microsoft_UI_Composition.ICompositionSupportsSystemBackdrop = try! thisPtr.QueryInterface()
    let uwpCompositor = UWP.Compositor()
    let uwpClearBrush = try! uwpCompositor.createColorBrush(Colors.transparent)
    try! supportsSystemBackdrop.put_SystemBackdrop(uwpClearBrush)

    let hwnd = appWindow.getHWND()

    // The window must be a layered window to be drawn transparently.
    let exStyle = GetWindowLongPtrW(hwnd, GWL_EXSTYLE)
    SetWindowLongPtrW(
      hwnd,
      GWL_EXSTYLE,
      exStyle | LONG_PTR(WS_EX_LAYERED)
    )

    // Disable the system border and drop shadow.
    var policy: DWMNCRENDERINGPOLICY = DWMNCRP_DISABLED
    _ = withUnsafePointer(to: &policy) { policyPtr in
      DwmSetWindowAttribute(
        hwnd,
        DWORD(DWMWA_NCRENDERING_POLICY.rawValue),
        policyPtr,
        UInt32(MemoryLayout<DWMNCRENDERINGPOLICY>.size)
      )
    }
  }

  public func setBackdropStyle(_ backdropStyle: WindowBackdropStyle) {
    switch backdropStyle {
    case .default:
      systemBackdrop = nil
    case .transparent:
      systemBackdrop = nil
      enableTransparentBackdrop()
    case .acrylic:
      systemBackdrop = DesktopAcrylicBackdrop()
    case .mica:
      let mica = MicaBackdrop()
      mica.kind = .base 
      systemBackdrop = mica
    case .micaAlt:
      let mica = MicaBackdrop()
      mica.kind = .baseAlt 
      systemBackdrop = mica
    }
  }
}

#endif