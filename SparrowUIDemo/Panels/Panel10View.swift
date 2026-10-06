import Foundation
import SparrowUI
import SparrowUIFoundation

struct Panel10View: PanelView {
  var body: some View {
    Color.blue
      .mask(gradient)
  }

  private var gradient: some View {
    LinearGradient(
      stops: [
        .init(color: .black, location: 0),
        .init(color: .clear, location: 1),
      ],
      startPoint: .leading,
      endPoint: .trailing,
    )
  }
}
