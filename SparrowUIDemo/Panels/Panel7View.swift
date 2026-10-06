import Foundation
import SparrowUI
import SparrowUIFoundation

struct Panel7View: PanelView {
  var body: some View {
    Group { geom in
      Color.blue.opacity(0.1)

      Group {
        TabVisorShape(offset: $offset)
          .fill(.primaryBackground)
          .stroke(.primaryText.opacity(0.1))
          .padding(.top, 20)
          .shadow(color: .primaryText.opacity(0.4), radius: 8)
          .onPointerDown { event in
            withAnimation {
              let clickX = event.location.point(in: .view).x
              let centeredOffset = clickX - TabVisorShape.Metrics.width / 2
              offset = clamp(
                centeredOffset,
                TabVisorShape.Metrics.cornerSize,
                geom.width - 100 - TabVisorShape.Metrics.width - TabVisorShape.Metrics.cornerSize,
              )
            }
          }
      }
      .height(100)
      .padding(.horizontal, 50)
      .alignment(.center)
      .clipped()
    }
  }

  @State private var offset: CGFloat = 100
}

private struct TabVisorShape: Shape {
  @Binding var offset: CGFloat

  enum Metrics {
    static let cornerRadius: CGFloat = 8
    static let width: CGFloat = 100
    static let cornerSize = SquircleGeometry.cornerSizeForRoundedRect(withCornerRadius: cornerRadius)
  }

  func path(in rect: CGRect) -> Path {
    .init { path in
      path.begin(at: .init(x: rect.minX, y: rect.centerY))
      
      path.line(to: .init(x: rect.minX + offset - Metrics.cornerSize, y: rect.centerY))
      path.squircleCorner(to: .init(x: rect.minX + offset, y: rect.centerY - Metrics.cornerSize), ending: .vertical)

      path.line(to: .init(x: rect.minX + offset, y: rect.minY + Metrics.cornerSize))
      path.squircleCorner(to: .init(x: rect.minX + offset + Metrics.cornerSize, y: rect.minY), ending: .horizontal)

      path.line(to: .init(x: rect.minX + offset + Metrics.width - Metrics.cornerSize, y: rect.minY))
      path.squircleCorner(to: .init(x: rect.minX + offset + Metrics.width, y: rect.minY + Metrics.cornerSize), ending: .vertical)

      path.line(to: .init(x: rect.minX + offset + Metrics.width, y: rect.centerY - Metrics.cornerSize))
      path.squircleCorner(to: .init(x: rect.minX + offset + Metrics.width + Metrics.cornerSize, y: rect.centerY), ending: .horizontal)

      path.line(to: .init(x: rect.maxX, y: rect.centerY))
      path.line(to: .init(x: rect.maxX, y: rect.maxY))
      path.line(to: .init(x: rect.minX, y: rect.maxY))
      path.end()
    }
  }
}
