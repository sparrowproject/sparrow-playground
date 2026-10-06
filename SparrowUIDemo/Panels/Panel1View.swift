import Foundation
import SparrowUI

struct Panel1View: PanelView {
  var body: some View {
    Group { geom in
      Rectangle()
        .fill(Color(.init(gray: 0.9)))

      RoundedRectangle(cornerRadius: 16)
        .fill(Color.red.opacity(0.4))
        .width(geom.width - 40)
        .height(geom.height - 40)
        .offset(x: 20, y: 20)
    }
  }
}
