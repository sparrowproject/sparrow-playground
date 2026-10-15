#if os(Windows)
import struct UWP.Color
import SparrowUIFoundation
import WinAppSDK
import WindowsFoundation

extension CoreViewAnimation {
  func toCompositionAnimation(withTargetValue value: Float, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .linear(let duration, _):
      with(try! compositor.createScalarKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.linearFunction)
        $0.duration = .init(duration)
      }
    case .easeIn(let duration, _):
      with(try! compositor.createScalarKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInFunction)
        $0.duration = .init(duration)
      }
    case .easeOut(let duration, _):
      with(try! compositor.createScalarKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeOutFunction)
        $0.duration = .init(duration)
      }
    case .easeInOut(let duration, _):
      with(try! compositor.createScalarKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInOutFunction)
        $0.duration = .init(duration)
      }
    case .bezier(let p1, let p2, let p3, let p4, let duration, _):
      with(try! compositor.createScalarKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.bezierFunction(p1, p2, p3, p4))
        $0.duration = .init(duration)
      }
    }
  }

  func toCompositionAnimation(withTargetValue value: Vector2, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .linear(let duration, _):
      with(try! compositor.createVector2KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.linearFunction)
        $0.duration = .init(duration)
      }
    case .easeIn(let duration, _):
      with(try! compositor.createVector2KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInFunction)
        $0.duration = .init(duration)
      }
    case .easeOut(let duration, _):
      with(try! compositor.createVector2KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeOutFunction)
        $0.duration = .init(duration)
      }
    case .easeInOut(let duration, _):
      with(try! compositor.createVector2KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInOutFunction)
        $0.duration = .init(duration)
      }
    case .bezier(let p1, let p2, let p3, let p4, let duration, _):
      with(try! compositor.createVector2KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.bezierFunction(p1, p2, p3, p4))
        $0.duration = .init(duration)
      }
    }
  }

  func toCompositionAnimation(withTargetValue value: Vector3, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .linear(let duration, _):
      with(try! compositor.createVector3KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.linearFunction)
        $0.duration = .init(duration)
      }
    case .easeIn(let duration, _):
      with(try! compositor.createVector3KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInFunction)
        $0.duration = .init(duration)
      }
    case .easeOut(let duration, _):
      with(try! compositor.createVector3KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeOutFunction)
        $0.duration = .init(duration)
      }
    case .easeInOut(let duration, _):
      with(try! compositor.createVector3KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInOutFunction)
        $0.duration = .init(duration)
      }
    case .bezier(let p1, let p2, let p3, let p4, let duration, _):
      with(try! compositor.createVector3KeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.bezierFunction(p1, p2, p3, p4))
        $0.duration = .init(duration)
      }
    }
  }

  func toCompositionAnimation(withTargetValue value: UWP.Color, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .linear(let duration, _):
      with(try! compositor.createColorKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.linearFunction)
        $0.duration = .init(duration)
      }
    case .easeIn(let duration, _):
      with(try! compositor.createColorKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInFunction)
        $0.duration = .init(duration)
      }
    case .easeOut(let duration, _):
      with(try! compositor.createColorKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeOutFunction)
        $0.duration = .init(duration)
      }
    case .easeInOut(let duration, _):
      with(try! compositor.createColorKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInOutFunction)
        $0.duration = .init(duration)
      }
    case .bezier(let p1, let p2, let p3, let p4, let duration, _):
      with(try! compositor.createColorKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.bezierFunction(p1, p2, p3, p4))
        $0.duration = .init(duration)
      }
    }
  }

  func toCompositionAnimation(withTargetValue value: CompositionPath, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .linear(let duration, _):
      with(try! compositor.createPathKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.linearFunction)
        $0.duration = .init(duration)
      }
    case .easeIn(let duration, _):
      with(try! compositor.createPathKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInFunction)
        $0.duration = .init(duration)
      }
    case .easeOut(let duration, _):
      with(try! compositor.createPathKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeOutFunction)
        $0.duration = .init(duration)
      }
    case .easeInOut(let duration, _):
      with(try! compositor.createPathKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.easeInOutFunction)
        $0.duration = .init(duration)
      }
    case .bezier(let p1, let p2, let p3, let p4, let duration, _):
      with(try! compositor.createPathKeyFrameAnimation()!) {
        try! $0.insertKeyFrame(1, value, compositor.bezierFunction(p1, p2, p3, p4))
        $0.duration = .init(duration)
      }
    }
  }
}

extension CoreViewAnimation {
  func toAnimationController(compositor: Compositor) -> AnimationController {
    let controller = try! compositor.createAnimationController()!
    let progress =
      switch self {
      case .linear(let duration, let timeOffset):
        timeOffset / duration
      case .easeIn(let duration, let timeOffset):
        timeOffset / duration
      case .easeOut(let duration, let timeOffset):
        timeOffset / duration
      case .easeInOut(let duration, let timeOffset):
        timeOffset / duration
      case .bezier(_, _, _, _, let duration, let timeOffset):
        timeOffset / duration
      }
    controller.progress = Float(progress)
    return controller
  }
}

extension Compositor {
  fileprivate var linearFunction: CompositionEasingFunction {
    try! createCubicBezierEasingFunction(
      .init(x: 0.0, y: 0.0),
      .init(x: 1.0, y: 1.0),
    )!
  }

  fileprivate var easeInFunction: CompositionEasingFunction {
    try! createCubicBezierEasingFunction(
      .init(x: 0.42, y: 0.0),
      .init(x: 1.0, y: 1.0),
    )!
  }

  fileprivate var easeOutFunction: CompositionEasingFunction {
    try! createCubicBezierEasingFunction(
      .init(x: 0.0, y: 0.0),
      .init(x: 0.58, y: 1.0),
    )!
  }

  fileprivate var easeInOutFunction: CompositionEasingFunction {
    try! createCubicBezierEasingFunction(
      .init(x: 0.42, y: 0.0),
      .init(x: 0.58, y: 1.0),
    )!
  }

  fileprivate func bezierFunction(_ p1: Float, _ p2: Float, _ p3: Float, _ p4: Float) -> CompositionEasingFunction {
    try! createCubicBezierEasingFunction(
      .init(x: p1, y: p2),
      .init(x: p3, y: p4),
    )!
  }
}

#endif