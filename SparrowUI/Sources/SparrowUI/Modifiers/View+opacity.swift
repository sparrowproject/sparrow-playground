import Foundation
import SparrowUICore

extension View {
  public func opacity(_ opacity: @autoclosure @MainActor @escaping () -> CGFloat) -> some View {
    modifier(_OpacityModifier(opacity: opacity))
  }
}

@MainActor
public struct _OpacityModifier {
  let opacity: @MainActor () -> CGFloat
}

extension _OpacityModifier: ViewModifier {
  public typealias Body = Never
}

extension _OpacityModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.opacity = opacity
  }
}
