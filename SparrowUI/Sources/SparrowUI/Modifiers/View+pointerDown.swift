import SparrowUICore

extension View {
  public func onPointerDown(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_PointerDownModifier(action: { _ in action() }))
  }
  public func onPointerDown(perform action: @MainActor @escaping (PointerEvent) -> Void) -> some View {
    modifier(_PointerDownModifier(action: action))
  }
}

@MainActor
public struct _PointerDownModifier {
  let action: @MainActor (PointerEvent) -> Void
}

extension _PointerDownModifier: ViewModifier {
  public typealias Body = Never
}

extension _PointerDownModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onPointerDown.add({ [weak view] event in
      guard let view else { return }
      action(_AnyPointerEvent(event: event, view: view))
    })
  }
}
