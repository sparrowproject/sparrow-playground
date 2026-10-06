import SparrowUICore

extension View {
  public func onPointerWheel(perform action: @MainActor @escaping (PointerWheelEvent) -> Void) -> some View {
    modifier(_PointerWheelModifier(action: action))
  }
}

@MainActor
public struct _PointerWheelModifier {
  let action: @MainActor (PointerWheelEvent) -> Void
}

extension _PointerWheelModifier: ViewModifier {
  public typealias Body = Never
}

extension _PointerWheelModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onPointerWheel.add({ [weak view] event in
      guard let view else { return }
      action(_PointerWheelEvent(event: event, view: view))
    })
  }
}
