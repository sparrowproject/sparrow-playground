#if os(Windows)
@_spi(WinRTInternal) import WinAppSDK
import WinAppSupport
import WinSDK

extension AppWindow {
  public func addChildWindow(_ window: AppWindow) {
    guard let parentHwnd = getHWND() else {
      assertionFailure("Failed to get parent HWND")
      return
    }

    guard let childHwnd = window.getHWND() else {
      assertionFailure("Failed to get child HWND")
      return
    }

    SetWindowLongPtrW(
      childHwnd,
      GWLP_HWNDPARENT,
      LONG_PTR(Int(bitPattern: parentHwnd)),
    )

    // // Set the popup style, disabling resize handles, etc.
    SetWindowLongPtrW(
      childHwnd,
      GWL_STYLE,
      LONG_PTR(WS_POPUP),
    )

    // Also configure the child window as a tool window.
    let exStyle = GetWindowLongPtrW(childHwnd, GWL_EXSTYLE)
    SetWindowLongPtrW(
      childHwnd,
      GWL_EXSTYLE,
      exStyle | LONG_PTR(WS_EX_TOOLWINDOW) | LONG_PTR(WS_EX_NOACTIVATE),
    )
  }

  /// Make the window transparent to hit testing.
  public func disableHitTesting(_ value: Bool = true) {
    let hwnd = getHWND()!
    let exStyle = GetWindowLongPtrW(hwnd, GWL_EXSTYLE)
    SetWindowLongPtrW(
      hwnd,
      GWL_EXSTYLE,
      exStyle | LONG_PTR(WS_EX_TRANSPARENT),
    )
  }

  public func setBorderStyle(_ borderStyle: WindowBorderStyle) {
    print(">>> setBorderStyle: \(borderStyle)")

    let hwnd = getHWND()!

    var borderColor: COLORREF = DWMWA_COLOR_NONE
    _ = withUnsafePointer(to: &borderColor) { borderColorPtr in
      DwmSetWindowAttribute(
        hwnd,
        DWORD(DWMWA_BORDER_COLOR.rawValue),
        borderColorPtr,
        UInt32(MemoryLayout<COLORREF>.size)
      )
    }

    var policy: DWMNCRENDERINGPOLICY =
      switch borderStyle {
      case .default:
        DWMNCRP_ENABLED
      case .none:
        DWMNCRP_DISABLED
      }
    _ = withUnsafePointer(to: &policy) { policyPtr in
      DwmSetWindowAttribute(
        hwnd,
        DWORD(DWMWA_NCRENDERING_POLICY.rawValue),
        policyPtr,
        UInt32(MemoryLayout<DWMNCRENDERINGPOLICY>.size)
      )
    }
  }

  // public func setBackdropStyle(_ backdropStyle: WindowBackdropStyle) {
  //   print(">>> setBackdropStyle: \(backdropStyle)")

  //   var useHostBackdropBrush = WindowsBool(false)
  //   _ = withUnsafePointer(to: &useHostBackdropBrush) { useHostBackdropBrushPtr in
  //     DwmSetWindowAttribute(
  //       getHWND()!,
  //       DWORD(DWMWA_USE_HOSTBACKDROPBRUSH.rawValue),
  //       useHostBackdropBrushPtr,
  //       UInt32(MemoryLayout<WindowsBool>.size)
  //     )
  //   }

  //   var systemBackdropType: DWM_SYSTEMBACKDROP_TYPE =
  //     switch backdropStyle {
  //     case .default:
  //       DWMSBT_AUTO
  //     case .transparent:
  //       DWMSBT_NONE
  //     case .acrylic:
  //       DWMSBT_TRANSIENTWINDOW
  //     case .mica:
  //       DWMSBT_MAINWINDOW
  //     case .micaAlt:
  //       DWMSBT_TABBEDWINDOW
  //     }
  //   _ = withUnsafePointer(to: &systemBackdropType) { systemBackdropTypePtr in
  //     DwmSetWindowAttribute(
  //       getHWND()!,
  //       DWORD(DWMWA_SYSTEMBACKDROP_TYPE.rawValue),
  //       systemBackdropTypePtr,
  //       UInt32(MemoryLayout<DWM_SYSTEMBACKDROP_TYPE>.size)
  //     )
  //   }
  // }

  // public func setCornerStyle(_ cornerStyle: WindowCornerStyle) {
  //   print(">>> setCornerStyle: \(cornerStyle)")

  //   var cornerPref: DWM_WINDOW_CORNER_PREFERENCE =
  //     switch cornerStyle {
  //     case .system:
  //       DWMWCP_DEFAULT
  //     case .square:
  //       DWMWCP_DONOTROUND
  //     case .round:
  //       DWMWCP_ROUND
  //     case .roundSmall:
  //       DWMWCP_ROUNDSMALL
  //     }
  //   _ = withUnsafePointer(to: &cornerPref) { cornerPrefPtr in
  //     DwmSetWindowAttribute(
  //       getHWND()!,
  //       DWORD(DWMWA_WINDOW_CORNER_PREFERENCE.rawValue),
  //       cornerPrefPtr,
  //       UInt32(MemoryLayout<DWM_WINDOW_CORNER_PREFERENCE>.size)
  //     )
  //   }
  // }
}

#endif