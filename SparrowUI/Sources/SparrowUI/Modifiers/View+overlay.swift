import SparrowUICore

extension View {
  /// Inserts a top-most child view.
  public func overlay<V: View>(
    _ overlay: @autoclosure @MainActor @escaping () -> V,
  ) -> some View {
    modifier(_OverlayModifier(overlay: overlay))
  }
}

@MainActor
public struct _OverlayModifier<V: View> {
  let overlay: @MainActor () -> V
}

extension _OverlayModifier: ViewModifier {
  public typealias Body = Never
}

extension _OverlayModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    let overlay = ViewBuilder(content: overlay()).buildView(context: view.context)
    view.overlay = { overlay }
  }
}