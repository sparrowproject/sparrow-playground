import SparrowUICore

extension View {
  public func clipped(_ clipped: @autoclosure @MainActor @escaping () -> Bool = true) -> some View {
    modifier(_ClippedModifier(clipped: clipped))
  }
}

@MainActor
public struct _ClippedModifier {
  let clipped: @MainActor () -> Bool
}

extension _ClippedModifier: ViewModifier {
  public typealias Body = Never
}

extension _ClippedModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.clipToBounds = clipped
  }
}
