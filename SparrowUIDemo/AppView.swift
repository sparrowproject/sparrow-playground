import Foundation
import Observation
import SparrowUI

@MainActor
@Observable
final class AppViewModel {
  init() {
    panels[selectedIndex].selectorViewModel.isSelected = true
  }

  @MainActor
  struct Panel {
    let selectorViewModel = PanelSelectorViewModel()
    let panelView: AnyView

    init<Content: PanelView>(
      panelView: () -> Content
    ) {
      self.panelView = AnyView(panelView())
    }
  }

  let panels: [Panel] = [
    .init { Panel0View() },
    .init { Panel1View() },
    .init { Panel2View() },
    .init { Panel3View() },
    .init { Panel4View() },
    .init { Panel5View() },
    .init { Panel6View() },
    .init { Panel7View() },
    .init { Panel8View() },
    .init { Panel9View() },
    .init { Panel10View() },
    .init { Panel11View() },
    .init { Panel12View() },
    .init { Panel13View() },
    .init { Panel14View() },
  ]

  var sidebarWidth: CGFloat = 200

  var selectedIndex = 0 {
    didSet {
      panels[oldValue].selectorViewModel.isSelected = false
      panels[selectedIndex].selectorViewModel.isSelected = true
    }
  }

  func panelSelectorViewModel(for index: Int) -> PanelSelectorViewModel {
    panels[index].selectorViewModel
  }
}

struct AppView: View {
  let viewModel: AppViewModel

  var body: some View {
    Group { geom in
      Repeated(0..<viewModel.panels.count, id: \.self) { index in
        PanelSelector(viewModel: viewModel.panelSelectorViewModel(for: index), index: index) {
          viewModel.selectedIndex = index
        }
        .offset(x: 10, y: 34 * CGFloat(index) + 10)
        .width(selectorViewWidth(for: geom))
        .height(30)
      }
      .width(selectorViewWidth(for: geom))

      Repeated(0..<viewModel.panels.count, id: \.self) { index in
        panelView(atIndex: index)
          .visible(viewModel.selectedIndex == index)
      }
      .width(contentViewWidth(for: geom))
      .offset(contentViewPosition(for: geom))
    }
  }

  private func panelView(atIndex index: Int) -> some View {
    viewModel.panels[index].panelView
  }

  private func selectorViewWidth(for geom: GeometryProxy) -> CGFloat {
    viewModel.sidebarWidth - 20
  }

  private func contentViewWidth(for geom: GeometryProxy) -> CGFloat {
    geom.width - viewModel.sidebarWidth
  }

  private func contentViewPosition(for geom: GeometryProxy) -> CGPoint {
    .init(x: viewModel.sidebarWidth, y: 0)
  }
}

@MainActor
@Observable
final class PanelSelectorViewModel {
  var isSelected = false
}

struct PanelSelector: View {
  let viewModel: PanelSelectorViewModel
  let index: Int
  let clicked: () -> Void

  var body: some View {
    Button(action: clicked) { config in
      Group {
        RoundedRectangle(cornerRadius: 8)
          .fill(backgroundColor(for: config))
        Text("Panel \(index)")
          .font(.system(size: 14))
          .foregroundColor(.black)
          .alignment(.center)
      }
    }
  }

  private func backgroundColor(for config: ButtonConfig) -> Color {
    let baseOpacity: CGFloat =
      if config.isHovered {
        0.12
      } else if viewModel.isSelected {
        0.08
      } else {
        0
      }
    return .black.opacity(baseOpacity * (config.isPressed ? 0.5 : 1))
  }
}

protocol PanelView: View {
  init()
}
