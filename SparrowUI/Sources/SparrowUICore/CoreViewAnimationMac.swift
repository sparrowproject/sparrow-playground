#if os(macOS)
import AppKit

extension CoreViewAnimation {
  func toBasicAnimation() -> CABasicAnimation {
    switch self {
    case .default, .easeInOut:
      CABasicAnimation()
    }
  }
}

#endif