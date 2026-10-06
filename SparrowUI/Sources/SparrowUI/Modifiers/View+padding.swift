import Foundation
import SparrowUICore
import SparrowUIFoundation

extension View {
  public func padding(_ insets: @autoclosure @MainActor @escaping () -> EdgeInsets) -> some View {
    modifier(_PaddingModifier(insets: insets))
  }

  public func padding(
    _ edges: @autoclosure @MainActor @escaping () -> EdgeSet,
    _ value: @autoclosure @MainActor @escaping () -> CGFloat,
  ) -> some View {
    modifier(_PaddingModifier(insets: { .init(edges: edges(), value: value()) }))
  }
}

@MainActor
public struct _PaddingModifier {
  let insets: @MainActor () -> EdgeInsets
}

extension _PaddingModifier: ViewModifier {
  public typealias Body = Never
}

extension _PaddingModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.padding.append(insets)
  }
}
