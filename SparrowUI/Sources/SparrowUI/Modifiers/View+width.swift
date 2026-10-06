import Foundation
import SparrowUICore

extension View {
  public func width(_ width: @autoclosure @MainActor @escaping () -> CGFloat) -> some View {
    modifier(_WidthModifier(width: width))
  }
}

@MainActor
public struct _WidthModifier {
  var width: @MainActor () -> CGFloat
}

extension _WidthModifier: ViewModifier {
  public typealias Body = Never
}

extension _WidthModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.width = width
  }
}
