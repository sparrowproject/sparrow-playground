import SparrowUICore

extension View {
  public func onPointerMoved(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_PointerMovedModifier(action: { _ in action() }))
  }
  public func onPointerMoved(perform action: @MainActor @escaping (PointerEvent) -> Void) -> some View {
    modifier(_PointerMovedModifier(action: action))
  }
}

@MainActor
public struct _PointerMovedModifier {
  let action: @MainActor (PointerEvent) -> Void
}

extension _PointerMovedModifier: ViewModifier {
  public typealias Body = Never
}

extension _PointerMovedModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onPointerMoved.add({ [weak view] event in
      guard let view else { return }
      action(_AnyPointerEvent(event: event, view: view))
    })
  }
}
