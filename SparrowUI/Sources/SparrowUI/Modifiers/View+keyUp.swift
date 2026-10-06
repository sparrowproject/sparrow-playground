import SparrowUICore

extension View {
  public func onKeyUp(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_KeyUpModifier(action: { _ in action() }))
  }
  public func onKeyUp(perform action: @MainActor @escaping (KeyEvent) -> Void) -> some View {
    modifier(_KeyUpModifier(action: action))
  }
}

@MainActor
public struct _KeyUpModifier {
  let action: @MainActor (KeyEvent) -> Void
}

extension _KeyUpModifier: ViewModifier {
  public typealias Body = Never
}

extension _KeyUpModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onKeyUp.add({ event in
      action(_KeyEvent(event: event))
    })
  }
}
