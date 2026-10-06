import Foundation
import SparrowUI

struct Panel14View: PanelView {
  var body: some View {
    Group { geom in
      Rectangle()
        .fill(Color.primaryBackground)

      Group {
        Color.primaryText
          .width(100)
          .height(40)
          .alignment(.center)
      }
    }
    .colorScheme(forceDarkMode ? .dark : nil)
    .onPointerDown {
      forceDarkMode.toggle()
    }
  }

  @State private var forceDarkMode = false

  private var foregroundColor = Color(
    light: .blue,
    dark: .green.opacity(0.5),
  )
}