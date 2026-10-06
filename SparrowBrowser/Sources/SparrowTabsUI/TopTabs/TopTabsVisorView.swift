import Foundation
import SparrowDesignSystem
import SparrowUI

struct TopTabsVisorView: View {
  struct Options: OptionSet {
    let rawValue: Int
    static let noBorder = Options(rawValue: 1 << 0)
    static let noShadow = Options(rawValue: 1 << 1)
  }

  init(
    offset: @autoclosure @escaping @MainActor () -> CGFloat,
    width: @autoclosure @escaping @MainActor () -> CGFloat,
    options: @autoclosure @escaping @MainActor () -> Options,
  ) {
    self.offset = offset
    self.width = width
    self.options = options
  }

  var body: some View {
    Group { geom in
      // Visor is 2x the height of the container so that it can project a shadow.
      VisorShape(offset: offset, width: width)
        .fill(.primaryBackground)
        .stroke(borderColor)
        .height(geom.height * 2)
        .shadow(color: shadowColor, radius: StandardMetrics.shadowRadius)
        .visible(canShowVisor)

      // If the visor cannot be shown because `width` is too narrow, then just give up
      // and only draw a shadow line.
      Rectangle()
        .fill(.primaryBackground)
        .stroke(borderColor)
        .shadow(color: shadowColor, radius: StandardMetrics.shadowRadius)
        .offset(y: geom.height)
        .visible(!canShowVisor)
    }
  }

  private var offset: @MainActor () -> CGFloat
  private var width: @MainActor () -> CGFloat
  private var options: @MainActor () -> Options

  private var canShowVisor: Bool {
    width() >= 2 * VisorShape.Metrics.padding
  }

  private var borderColor: Color {
    options().contains(.noBorder) ? .clear : StandardColors.border
  }

  private var shadowColor: Color {
    options().contains(.noShadow) ? .clear : StandardColors.shadow
  }
}

private struct VisorShape: Shape {
  let offset: @MainActor () -> CGFloat
  let width: @MainActor () -> CGFloat

  enum Metrics {
    static let cornerRadius: CGFloat = 9
    static let padding = TopTabsView.Metrics.padding / 2
    static let cornerSize = SquircleGeometry.cornerSizeForRoundedRect(withCornerRadius: cornerRadius)
  }

  func path(in rect: CGRect) -> Path {
    .init { path in
      path.begin(at: .init(x: rect.minX, y: rect.centerY))
      
      path.line(to: .init(x: rect.minX + visorOffset - Metrics.cornerSize, y: rect.centerY))
      path.squircleCorner(to: .init(x: rect.minX + visorOffset, y: rect.centerY - Metrics.cornerSize), ending: .vertical)

      path.line(to: .init(x: rect.minX + visorOffset, y: rect.minY + Metrics.cornerSize))
      path.squircleCorner(to: .init(x: rect.minX + visorOffset + Metrics.cornerSize, y: rect.minY), ending: .horizontal)

      path.line(to: .init(x: rect.minX + visorOffset + visorWidth - Metrics.cornerSize, y: rect.minY))
      path.squircleCorner(to: .init(x: rect.minX + visorOffset + visorWidth, y: rect.minY + Metrics.cornerSize), ending: .vertical)

      path.line(to: .init(x: rect.minX + visorOffset + visorWidth, y: rect.centerY - Metrics.cornerSize))
      path.squircleCorner(to: .init(x: rect.minX + visorOffset + visorWidth + Metrics.cornerSize, y: rect.centerY), ending: .horizontal)

      path.line(to: .init(x: rect.maxX, y: rect.centerY))
      path.line(to: .init(x: rect.maxX, y: rect.maxY))
      path.line(to: .init(x: rect.minX, y: rect.maxY))
      path.end()
    }
  }

  private var visorOffset: CGFloat {
    offset() + Metrics.padding
  }

  private var visorWidth: CGFloat {
    width() - 2 * Metrics.padding
  }
}