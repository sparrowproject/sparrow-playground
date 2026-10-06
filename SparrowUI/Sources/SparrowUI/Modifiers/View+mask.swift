import SparrowUICore

extension View {
  public func mask<V: View>(_ mask: @autoclosure @MainActor @escaping () -> V) -> some View {
    modifier(_MaskModifier<V>(mask: mask))
  }
}

@MainActor
public struct _MaskModifier<V: View> {
  let mask: @MainActor () -> V
}

extension _MaskModifier: ViewModifier {
  public typealias Body = Never
}

extension _MaskModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    let context = view.context
    view.mask = {
      ViewBuilder(content: mask()).buildView(context: context)
    }
  }
}
