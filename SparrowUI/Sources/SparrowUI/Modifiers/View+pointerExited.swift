import SparrowUICore

extension View {
  public func onPointerExited(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_PointerExitedModifier(action: { _ in action() }))
  }
  public func onPointerExited(perform action: @MainActor @escaping (PointerEvent) -> Void) -> some View {
    modifier(_PointerExitedModifier(action: action))
  }
}

@MainActor
public struct _PointerExitedModifier {
  let action: @MainActor (PointerEvent) -> Void
}

extension _PointerExitedModifier: ViewModifier {
  public typealias Body = Never
}

extension _PointerExitedModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onPointerExited.add({ [weak view] event in
      guard let view else { return }
      action(_AnyPointerEvent(event: event, view: view))
    })
  }
}
