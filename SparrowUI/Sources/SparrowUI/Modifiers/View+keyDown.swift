import SparrowUICore

extension View {
  public func onKeyDown(perform action: @MainActor @escaping () -> Void) -> some View {
    modifier(_KeyDownModifier(action: { _ in action() }))
  }
  public func onKeyDown(perform action: @MainActor @escaping (KeyEvent) -> Void) -> some View {
    modifier(_KeyDownModifier(action: action))
  }
}

@MainActor
public struct _KeyDownModifier {
  let action: @MainActor (KeyEvent) -> Void
}

extension _KeyDownModifier: ViewModifier {
  public typealias Body = Never
}

extension _KeyDownModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onKeyDown.add({ event in
      action(_KeyEvent(event: event))
    })
  }
}
