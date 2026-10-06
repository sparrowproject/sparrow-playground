import SparrowUICore

extension View {
  public func scaleEffect(_ scale: @autoclosure @MainActor @escaping () -> Double) -> some View {
    modifier(_ScaleModifier(scale: scale))
  }
}

@MainActor
public struct _ScaleModifier {
  let scale: @MainActor () -> Double
}

extension _ScaleModifier: ViewModifier {
  public typealias Body = Never
}

extension _ScaleModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.scale = scale
  }
}
