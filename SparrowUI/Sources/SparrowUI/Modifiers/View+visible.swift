import SparrowUICore

extension View {
  public func visible(_ visible: @autoclosure @MainActor @escaping () -> Bool = true) -> some View {
    modifier(_VisibleModifier(visible: visible))
  }
}

@MainActor
public struct _VisibleModifier {
  let visible: @MainActor () -> Bool
}

extension _VisibleModifier: ViewModifier {
  public typealias Body = Never
}

extension _VisibleModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.visible = visible
  }
}
