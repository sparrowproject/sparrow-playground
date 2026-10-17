import Foundation

#if os(macOS)
import AppKit
#endif

@MainActor
public enum CoreViewAnimation {
  case linear(duration: TimeInterval = Self.defaultDuration, timeOffset: TimeInterval = 0)
  case easeIn(duration: TimeInterval = Self.defaultDuration, timeOffset: TimeInterval = 0)
  case easeOut(duration: TimeInterval = Self.defaultDuration, timeOffset: TimeInterval = 0)
  case easeInOut(duration: TimeInterval = Self.defaultDuration, timeOffset: TimeInterval = 0)
  case bezier(controlPoints: Float, _: Float, _: Float, _: Float, duration: TimeInterval = Self.defaultDuration, timeOffset: TimeInterval = 0)

  public static var `default`: Self = .easeInOut()
  public nonisolated static var defaultDuration: TimeInterval { 0.3 }
}

@MainActor
final class CoreViewAnimationInstance: NSObject {
  typealias ID = Int64

  init(animation: CoreViewAnimation) {
    id = Self.makeID()
    self.animation = animation
  }

  let id: ID

  /// This is intentionally mutable. With great power, comes great responsibility!
  var animation: CoreViewAnimation?

  func sample<Value>(from fromValue: Value, to toValue: Value, context: CoreViewContext, apply: @escaping (Value) -> Void) where Value: Lerpable {
    if !sampling {
      sampling = true
      #if os(macOS)
      context.sampleAnimation(CABasicAnimation(), step: animationStep, completion: animationCompletion)
      #endif
    }
    sampledValues.append(SomeSampledValue(fromValue: fromValue, toValue: toValue, apply: apply))
  }

  private static var usedID: Int64 = 0

  private static func makeID() -> Int64 {
    usedID += 1
    return usedID
  }

  private var sampling = false
  private var sampledValues = [SampledValue]()

  private func animationStep(_ progress: CGFloat) {
//    print(">>> animationStep, progress: \(progress)")
    for sampledValue in sampledValues {
      sampledValue.applyProgress(progress)
    }
  }

  private func animationCompletion() {
//    print(">>> animationCompletion")
    for sampledValue in sampledValues {
      sampledValue.applyProgress(1)
    }
    sampledValues.removeAll()
  }
}

protocol SampledValue {
  func applyProgress(_ progress: CGFloat)
}

struct SomeSampledValue<Value>: SampledValue where Value: Lerpable {
  let fromValue: Value
  let toValue: Value
  let apply: (Value) -> Void

  func applyProgress(_ progress: CGFloat) {
    self.apply(Value.lerp(fromValue, toValue, progress))
  }
}

protocol Lerpable {
  static func lerp(_ from: Self, _ to: Self, _ ratio: CGFloat) -> Self
}

extension CGFloat: Lerpable {
  static func lerp(_ from: CGFloat, _ to: CGFloat, _ ratio: CGFloat) -> CGFloat {
    ((to - from) * ratio) + from
  }
}

extension CGSize: Lerpable {
  static func lerp(_ from: CGSize, _ to: CGSize, _ ratio: CGFloat) -> CGSize {
    .init(
      width: CGFloat.lerp(from.width, to.width, ratio),
      height: CGFloat.lerp(from.height, to.height, ratio),
    )
  }
}
