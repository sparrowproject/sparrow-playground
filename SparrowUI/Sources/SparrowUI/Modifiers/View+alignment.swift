import SparrowUICore
import SparrowUIFoundation

extension View {
  public func alignment(_ alignment: @autoclosure @MainActor @escaping () -> Alignment) -> some View {
    modifier(_AlignmentModifier(alignment: alignment))
  }
}

@MainActor
public struct _AlignmentModifier {
  let alignment: @MainActor () -> Alignment
}

extension _AlignmentModifier: ViewModifier {
  public typealias Body = Never
}

extension _AlignmentModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.alignment = alignment
  }
}
