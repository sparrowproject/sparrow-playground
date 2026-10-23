import Foundation
import SparrowUI

struct Panel16View: PanelView {
  var body: some View {
    Group { geom in
      Rectangle()
        .fill(.primaryBackground)

      Group { geom in
        RoundedRectangle(cornerRadius: 6)
          .fill(.blue)

        RoundedRectangle(cornerRadius: 4.5)
          .fill(.primaryBackground)
          .width(geom.width - 3)
          .height(geom.height - 3)
          .alignment(.center)

        Group {
          Symbol(source: Self.grid)
            .tintColor(.blue)
            .alignment(.top)

          Image(source: source)
            .resizable()
            .tintColor(.blue)
            .readLoadingStatus(to: $status)
            .width(24)
            .height(24)
            .alignment(.bottom)
        }
        .padding(.all, 6)
      }
      .width(64)
      .height(64)
      .alignment(.center)

      Text("Loading status: \(status)")
        .alignment(.bottom)
        .padding(.bottom, 20)
    }
  }

  private let source = ImageSource.symbol(Self.grid)
  @State private var status = ImageLoadingStatus.idle

  private static var grid: SymbolSource {
    #if os(macOS)
    .init(systemName: "square.grid.2x2", size: 24)
    #elseif os(Windows)
    .init(glyph: "\u{e8a9}", size: 24) // ViewAll
    #endif
  }
}