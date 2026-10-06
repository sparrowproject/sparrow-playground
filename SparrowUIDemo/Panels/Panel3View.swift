import Foundation
import SparrowUI

struct Panel3View: PanelView {
  var body: some View {
    Group {
      background

      Group { geom in
        toolbarBackground

        backButton
          .offset(x: Metrics.buttonPadding, y: Metrics.buttonPadding)
        forwardButton
          .offset(x: 2 * Metrics.buttonPadding + Metrics.buttonSize, y: Metrics.buttonPadding)
        reloadStopButton
          .offset(x: 3 * Metrics.buttonPadding + 2 * Metrics.buttonSize, y: Metrics.buttonPadding)

        urlBar
          .offset(x: urlBarOffsetX(for: geom), y: Metrics.buttonPadding)
          .width(urlBarWidth(for: geom))

        menuButton
          .offset(x: geom.width - Metrics.buttonPadding - Metrics.buttonSize, y: Metrics.buttonPadding)
      }
      .alignment(.center)
      .height(2 * Metrics.buttonPadding + Metrics.buttonSize)
      .padding(.horizontal, 2 * Metrics.buttonPadding)
    }
  }

  private enum Metrics {
    static let buttonSize: CGFloat = 24
    static let buttonRadius: CGFloat = 6
    static let buttonPadding: CGFloat = 6
    static let urlBarMaxWidth: CGFloat = 400
  }

  private var background: some View {
    Color(.init(gray: 0.9))
  }

  private var toolbarBackground: some View {
    RoundedRectangle(cornerRadius: Metrics.buttonRadius + Metrics.buttonPadding)
      .fill(.white)
  }

  private var backButton: some View {
    Button(action: {
      print(">>> go back!")
    }, label: { config in
      Group {
        RoundedRectangle(cornerRadius: Metrics.buttonRadius)
          .fill(buttonBackground(for: config))
        Image(source: .resource(named: "back-chevron", withExtension: "svg"))
          .resizable()
          .tintColor(.black.opacity(0.6))
      }
      .opacity(buttonOpacity(for: config))
    })
    .width(Metrics.buttonSize)
    .height(Metrics.buttonSize)
  }

  private var forwardButton: some View {
    Button(action: {
      print(">>> go forward!")
    }, label: { config in
      Group {
        RoundedRectangle(cornerRadius: Metrics.buttonRadius)
          .fill(buttonBackground(for: config))
        Image(source: .resource(named: "forward-chevron", withExtension: "svg"))
          .resizable()
          .tintColor(.black.opacity(0.6))
      }
      .opacity(buttonOpacity(for: config))
    })
    .width(Metrics.buttonSize)
    .height(Metrics.buttonSize)
  }

  private var reloadStopButton: some View {
    Button(action: {
      print(">>> reload or stop!")
    }, label: { config in
      Group {
        RoundedRectangle(cornerRadius: Metrics.buttonRadius)
          .fill(buttonBackground(for: config))
      }
      .opacity(buttonOpacity(for: config))
    })
    .width(Metrics.buttonSize)
    .height(Metrics.buttonSize)
  }

  private var urlBar: some View {
    Button(action: {
      print(">>> edit url!")
    }, label: { config in
      Group {
        RoundedRectangle(cornerRadius: Metrics.buttonRadius)
          .fill(buttonBackground(for: config))
      }
      .opacity(buttonOpacity(for: config))
    })
    .height(Metrics.buttonSize)
  }

  private var menuButton: some View {
    Button(action: {
      print(">>> show menu!")
    }, label: { config in
      Group {
        RoundedRectangle(cornerRadius: Metrics.buttonRadius)
          .fill(buttonBackground(for: config))
      }
      .opacity(buttonOpacity(for: config))
    })
    .width(Metrics.buttonSize)
    .height(Metrics.buttonSize)
  }

  private func buttonBackground(for config: ButtonConfig) -> Color {
    .blue.opacity(0.3)
  }

  private func buttonOpacity(for config: ButtonConfig) -> CGFloat {
    if config.isPressed {
      0.6
    } else if config.isHovered {
      1
    } else {
      0.8
    }
  }

  private func urlBarWidth(for geom: GeometryProxy) -> CGFloat {
    let availableWidth = geom.width - 4 * Metrics.buttonSize - 6 * Metrics.buttonPadding
    return min(Metrics.urlBarMaxWidth, availableWidth)
  }

  private func urlBarOffsetX(for geom: GeometryProxy) -> CGFloat {
    let urlBarWidth = urlBarWidth(for: geom)
    let centeredOffsetX = geom.width / 2 - urlBarWidth / 2

    let minOffsetX = 3 * Metrics.buttonSize + 4 * Metrics.buttonPadding
    if centeredOffsetX < minOffsetX {
      return minOffsetX
    }
    return centeredOffsetX
  }
}
