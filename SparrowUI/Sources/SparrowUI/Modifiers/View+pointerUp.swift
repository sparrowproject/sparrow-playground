import SparrowUICore

extension View {
  public func onPointerUp(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_PointerUpModifier(action: { _ in action() }))
  }
  public func onPointerUp(perform action: @MainActor @escaping (PointerEvent) -> Void) -> some View {
    modifier(_PointerUpModifier(action: action))
  }
}

@MainActor
public struct _PointerUpModifier {
  let action: @MainActor (PointerEvent) -> Void
}

extension _PointerUpModifier: ViewModifier {
  public typealias Body = Never
}

extension _PointerUpModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onPointerUp.add({ [weak view] event in
      guard let view else { return }
      action(_AnyPointerEvent(event: event, view: view))
    })
  }
}
