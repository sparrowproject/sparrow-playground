#if os(macOS)
import AppKit
import SparrowUIFoundation

extension CoreViewAnimation {
  func toBasicAnimation() -> CABasicAnimation {
    switch self {
    case .default:
      CABasicAnimation()
    case .linear(let duration):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.timingFunction = CAMediaTimingFunction(name: .linear)
      }
    case .easeIn(let duration):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.timingFunction = CAMediaTimingFunction(name: .easeIn)
      }
    case .easeOut(let duration):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.timingFunction = CAMediaTimingFunction(name: .easeOut)
      }
    case .easeInOut(let duration):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      }
    }
  }
}

#endif