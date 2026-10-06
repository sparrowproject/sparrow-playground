import SparrowUI

extension View {
  public func contextMenu() -> some View {
    modifier(ContextMenuModifier())
  }
}

struct ContextMenuModifier: ViewModifier {
  func body(content: Content) -> some View {
    // TODO
    content
  }
}