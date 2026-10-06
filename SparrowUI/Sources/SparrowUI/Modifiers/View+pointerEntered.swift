import SparrowUICore

extension View {
  public func onPointerEntered(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_PointerEnteredModifier(action: { _ in action() }))
  }
  public func onPointerEntered(perform action: @MainActor @escaping (PointerEvent) -> Void) -> some View {
    modifier(_PointerEnteredModifier(action: action))
  }
}

@MainActor
public struct _PointerEnteredModifier {
  let action: @MainActor (PointerEvent) -> Void
}

extension _PointerEnteredModifier: ViewModifier {
  public typealias Body = Never
}

extension _PointerEnteredModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onPointerEntered.add({ [weak view] event in
      guard let view else { return }
      action(_AnyPointerEvent(event: event, view: view))
    })
  }
}
