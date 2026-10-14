import Foundation
import SparrowUI

struct Panel15View: PanelView {
  var body: some View {
    Group { geom in
      Rectangle()
        .fill(Color.primaryBackground)

      Image(source: source)
        .resizable()
        .width(64)
        .height(64)
        .alignment(.center)
    }
  }

  private let source = ImageSource.resource(named: "blossom-icon", withExtension: "svg")
}