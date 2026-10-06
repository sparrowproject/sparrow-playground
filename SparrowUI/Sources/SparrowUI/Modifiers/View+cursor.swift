import SparrowUICore
import SparrowUIFoundation

extension View {
  /// Used to override the cursor while the pointer is over this view.
  public func cursor(_ cursor: @autoclosure @MainActor @escaping () -> Cursor?) -> some View {
    modifier(_CursorModifier(cursor: cursor))
  }
}

@MainActor
public struct _CursorModifier {
  let cursor: @MainActor () -> Cursor?
}

extension _CursorModifier: ViewModifier {
  public typealias Body = Never
}

extension _CursorModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.cursor = cursor
  }
}
