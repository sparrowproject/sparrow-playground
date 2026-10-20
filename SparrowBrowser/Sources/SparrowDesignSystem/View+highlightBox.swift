import Foundation
import SparrowUI

extension View {
  public func highlightBox(
    when condition: @autoclosure @MainActor @escaping () -> Bool,
    cornerRadius: @autoclosure @MainActor @escaping () -> CGFloat = StandardMetrics.buttonCornerRadius,
    backgroundColor: @autoclosure @MainActor @escaping () -> Color = .primaryBackground,
  ) -> some View {
    modifier(HighlightBoxModifier(
      condition: condition,
      cornerRadius: cornerRadius,
      backgroundColor: backgroundColor,
    ))
  }
}

struct HighlightBoxModifier: ViewModifier {
  let condition: @MainActor () -> Bool
  let cornerRadius: @MainActor () -> CGFloat
  let backgroundColor: @MainActor () -> Color

  func body(content: Content) -> some View {
    Group {
      Group { geom in
        RoundedRectangle(cornerRadius: cornerRadius() + 1)
          .fill(StandardColors.highlight)
          .shadow(color: StandardColors.highlightShadow, radius: StandardMetrics.highlightShadowRadius)
          .width(geom.width + 2)
          .height(geom.height + 2)
          .offset(x: -1, y: -1)
       
        RoundedRectangle(cornerRadius: cornerRadius())
          .fill(backgroundColor())
      }
      .opacity(condition() ? 1 : 0)

      content
    }
  }
}