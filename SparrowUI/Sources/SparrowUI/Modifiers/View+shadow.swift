import Foundation
import SparrowUICore

extension View {
  public func shadow(
    color: @autoclosure @MainActor @escaping () -> Color,
    radius: @autoclosure @MainActor @escaping () -> CGFloat,
    x: @autoclosure @MainActor @escaping () -> CGFloat = 0,
    y: @autoclosure @MainActor @escaping () -> CGFloat = 0,
  ) -> some View {
    modifier(_ShadowModifier(
      color: color,
      radius: radius,
      x: x,
      y: y,
    ))
  }
}

@MainActor
public struct _ShadowModifier {
  var color: @MainActor () -> Color
  var radius: @MainActor () -> CGFloat
  var x: @MainActor () -> CGFloat
  var y: @MainActor () -> CGFloat
}

extension _ShadowModifier: ViewModifier {
  public typealias Body = Never
}

extension _ShadowModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    let colorSchemeGetter = view.effectiveColorSchemeGetter
    view.shadow = { CoreShadow(
        color: color().resolved(with: colorSchemeGetter()),
        radius: radius(),
        x: x(),
        y: y(),
      )
    }
  }
}
