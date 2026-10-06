import SparrowUICore

extension View {
  public func allowsAnimation(_ allowsAnimation: @autoclosure @MainActor @escaping () -> Bool = true) -> some View {
    modifier(_AllowsAnimationModifier(allowsAnimation: allowsAnimation))
  }
}

@MainActor
public struct _AllowsAnimationModifier {
  let allowsAnimation: @MainActor () -> Bool
}

extension _AllowsAnimationModifier: ViewModifier {
  public typealias Body = Never
}

extension _AllowsAnimationModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.allowsAnimation = allowsAnimation
  }
}
