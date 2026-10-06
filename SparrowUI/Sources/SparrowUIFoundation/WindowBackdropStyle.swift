#if os(macOS)
import AppKit
#endif

public enum WindowBackdropStyle: Sendable, Equatable {
  case transparent
  
  #if os(macOS)
  case material(
    NSVisualEffectView.Material,
    blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
    state: NSVisualEffectView.State = .active,
  )
  #elseif os(Windows)
  case acrylic
  case mica
  case micaAlt
  #endif
}

extension WindowBackdropStyle {
  public static var `default`: Self {
    .menu
  }

  public static var menu: Self {
    #if os(macOS)
    .material(.menu)
    #elseif os(Windows)
    .acrylic
    #endif
  }
}