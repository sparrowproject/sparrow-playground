#if os(macOS)
import AppKit
import SparrowUIFoundation

extension CoreViewAnimation {
  func toBasicAnimation() -> CABasicAnimation {
    switch self {
    case .default:
      CABasicAnimation()
    case .linear(let duration, let timeOffset):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.beginTime = CACurrentMediaTime() - timeOffset
        $0.timingFunction = CAMediaTimingFunction(name: .linear)
      }
    case .easeIn(let duration, let timeOffset):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.beginTime = CACurrentMediaTime() - timeOffset
        $0.timingFunction = CAMediaTimingFunction(name: .easeIn)
      }
    case .easeOut(let duration, let timeOffset):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.beginTime = CACurrentMediaTime() - timeOffset
        $0.timingFunction = CAMediaTimingFunction(name: .easeOut)
      }
    case .easeInOut(let duration, let timeOffset):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.beginTime = CACurrentMediaTime() - timeOffset
        $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      }
    case .bezier(let p1, let p2, let p3, let p4, let duration, let timeOffset):
      with(CABasicAnimation()) {
        $0.duration = duration
        $0.beginTime = CACurrentMediaTime() - timeOffset
        $0.timingFunction = CAMediaTimingFunction(controlPoints: p1, p2, p3, p4)
      }
    }
  }
}

#endif