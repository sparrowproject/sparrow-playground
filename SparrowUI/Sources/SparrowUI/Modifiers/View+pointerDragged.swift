import SparrowUICore

extension View {
  public func onPointerDragged(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_PointerDraggedModifier(action: { _ in action() }))
  }
  public func onPointerDragged(perform action: @MainActor @escaping (PointerDragEvent) -> Void) -> some View {
    modifier(_PointerDraggedModifier(action: action))
  }
}

@MainActor
public struct _PointerDraggedModifier {
  let action: @MainActor (PointerDragEvent) -> Void
}

extension _PointerDraggedModifier: ViewModifier {
  public typealias Body = Never
}

extension _PointerDraggedModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onPointerDragged.add({ [weak view] event in
      guard let view else { return }
      action(_PointerDragEvent(event: event, view: view))
    })
  }
}
