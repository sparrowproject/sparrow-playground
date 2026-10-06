import Foundation
import SparrowUI
import SparrowUIFoundation

struct Panel8View: PanelView {
  var body: some View {
    ContinuousRoundedRect(radius: radius)
      .fill(.red.opacity(0.5))
      .shadow(color: .primaryText.opacity(0.8), radius: 12)
      .padding(.all, 50)
      .onPointerEntered {
        withAnimation {
          radius = 40
        }
      }
      .onPointerExited {
        withAnimation {
          radius = 20
        }
      }
  }

  @State private var radius: CGFloat = 20
}

struct ContinuousRoundedRect: Shape {
  init(radius: @autoclosure @escaping () -> CGFloat) {
    self.radius = radius
  }

  private let radius: () -> CGFloat

  func path(in rect: CGRect) -> Path {
    let cornerSize = SquircleGeometry.cornerSizeForRoundedRect(withCornerRadius: radius())
    let steps = SquircleGeometry.Steps.fixed(16)

    return Path { p in
      p.begin(at: CGPoint(x: rect.minX + cornerSize, y: rect.minY))

      p.line(to: CGPoint(x: rect.maxX - cornerSize, y: rect.minY))
      p.squircleCorner(to: .init(x: rect.maxX, y: rect.minY + cornerSize), ending: .vertical, steps: steps)

      p.line(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerSize))
      p.squircleCorner(to: .init(x: rect.maxX - cornerSize, y: rect.maxY), ending: .horizontal, steps: steps)

      p.line(to: CGPoint(x: rect.minX + cornerSize, y: rect.maxY))
      p.squircleCorner(to: .init(x: rect.minX, y: rect.maxY - cornerSize), ending: .vertical, steps: steps)

      p.line(to: CGPoint(x: rect.minX, y: rect.minY + cornerSize))
      p.squircleCorner(to: .init(x: rect.minX + cornerSize, y: rect.minY), ending: .horizontal, steps: steps)

      p.end()
    }
  }
}