import Foundation
import SparrowUI
import SparrowUIFoundation

struct Panel9View: PanelView {
  var body: some View {
    LinearGradient(
      stops: [
        .init(color: .blue, location: 0),
        .init(color: .red, location: offset),
      ],
      startPoint: .leading,
      endPoint: .trailing,
    )
    .readSize(to: $size)
    .onPointerMoved {
      let sidebarWidth: CGFloat = 200 // TODO: Either plumb this through or figure out a way to express relative coordinates!
      offset = clamp(($0.location.point(in: .host).x - sidebarWidth) / size.width, 0, 1)
    }
  }

  @State private var size: CGSize = .zero
  @State private var offset: CGFloat = 1
}
