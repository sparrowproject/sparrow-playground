#if os(Windows)
import struct UWP.Color
import WinAppSDK
import WindowsFoundation

extension CoreViewAnimation {
  func toCompositionAnimation(withTargetValue value: Float, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .default, .easeInOut:
      let animation = try! compositor.createScalarKeyFrameAnimation()!
      try! animation.insertKeyFrame(1, value, compositor.easeInOutFunction)
      return animation
    }
  }

  func toCompositionAnimation(withTargetValue value: Vector2, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .default, .easeInOut:
      let animation = try! compositor.createVector2KeyFrameAnimation()!
      try! animation.insertKeyFrame(1, value, compositor.easeInOutFunction)
      return animation
    }
  }

  func toCompositionAnimation(withTargetValue value: Vector3, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .default, .easeInOut:
      let animation = try! compositor.createVector3KeyFrameAnimation()!
      try! animation.insertKeyFrame(1, value, compositor.easeInOutFunction)
      return animation
    }
  }

  func toCompositionAnimation(withTargetValue value: UWP.Color, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .default, .easeInOut:
      let animation = try! compositor.createColorKeyFrameAnimation()!
      try! animation.insertKeyFrame(1, value, compositor.easeInOutFunction)
      return animation
    }
  }

  func toCompositionAnimation(withTargetValue value: CompositionPath, compositor: Compositor) -> CompositionAnimation {
    switch self {
    case .default, .easeInOut:
      let animation = try! compositor.createPathKeyFrameAnimation()!
      try! animation.insertKeyFrame(1, value, compositor.easeInOutFunction)
      return animation
    }
  }
}

extension Compositor {
  fileprivate var easeInOutFunction: CompositionEasingFunction {
    try! createCubicBezierEasingFunction(
      .init(x: 0.42, y: 0.0),
      .init(x: 0.58, y: 1.0),
    )!
  }
}

#endif