import Foundation
import SparrowUICore

extension View {
  public func offset(_ offset: @autoclosure @MainActor @escaping () -> CGPoint) -> some View {
    modifier(_OffsetModifier(offsetX: { offset().x }, offsetY: { offset().y }))
  }

  public func offset(
    x: @autoclosure @MainActor @escaping () -> CGFloat,
  ) -> some View {
    modifier(_OffsetModifier(offsetX: x, offsetY: nil))
  }

  public func offset(
    y: @autoclosure @MainActor @escaping () -> CGFloat,
  ) -> some View {
    modifier(_OffsetModifier(offsetX: nil, offsetY: y))
  }

  public func offset(
    x: @autoclosure @MainActor @escaping () -> CGFloat,
    y: @autoclosure @MainActor @escaping () -> CGFloat,
  ) -> some View {
    modifier(_OffsetModifier(offsetX: x, offsetY: y))
  }
}

@MainActor
public struct _OffsetModifier {
  var offsetX: (@MainActor () -> CGFloat)?
  var offsetY: (@MainActor () -> CGFloat)?
}

extension _OffsetModifier: ViewModifier {
  public typealias Body = Never
}

extension _OffsetModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    if let offsetX {
      view.offsetX = offsetX
    }
    if let offsetY {
      view.offsetY = offsetY
    }
  }
}
