import Foundation
import SparrowAddressBar
import SparrowCommands
import SparrowDesignSystem
import SparrowDownloadsUI
import SparrowSpacesUI
import SparrowUI

public struct ContentToolbarView: View {
  public enum Action {
    case goBack
    case goForward
    case reload
    case stop
    case command(SparrowCommand.ID)
    case addressBar(AddressBarView.Action)
    case spaceSelector(SpaceSelectorView.Action)
    case downloads(RecentDownloadsView.Action)
  }

  public enum Metrics {
    public static let buttonPadding: CGFloat = 6

    static let addressBarMaxWidth: CGFloat = 500
  }

  public init(viewModel: ContentToolbarViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      background

      Group { geom in
        backButton
          .width(buttonSize(for: geom))
          .offset(x: Metrics.buttonPadding)

        forwardButton
          .width(buttonSize(for: geom))
          .offset(x: 2 * Metrics.buttonPadding + buttonSize(for: geom))
        reloadStopButton
          .width(buttonSize(for: geom))
          .offset(x: 3 * Metrics.buttonPadding + 2 * buttonSize(for: geom))

        addressBar
          .offset(x: addressBarOffsetX(for: geom))
          .width(addressBarWidth(for: geom))

        recentDownloadsButton
          .width(buttonSize(for: geom))
          .offset(x: geom.width - 3 * (Metrics.buttonPadding + buttonSize(for: geom)))
          .visible(!viewModel.recentDownloadsViewModel.isEmpty)

        menuButton
          .width(buttonSize(for: geom))
          .offset(x: geom.width - 2 * (Metrics.buttonPadding + buttonSize(for: geom)))
        
        spaceSelectorToggleButton
          .width(buttonSize(for: geom))
          .offset(x: geom.width - (Metrics.buttonPadding + buttonSize(for: geom)))
      }
      .padding(.vertical, Metrics.buttonPadding)
      .padding(viewModel.insets)

      divider
      progressBar
    }
    .onChange(of: viewModel.tabModel.url, perform: viewModel.handleURLChanged)
    .readColorScheme(to: $colorScheme)
  }

  private let viewModel: ContentToolbarViewModel
  private let action: (Action) -> Void
  @State private var colorScheme: ColorScheme = .light

  private var background: some View {
    Color.primaryBackground
  }

  private var backButton: some View {
    PopoverButton(
      content: { controller in
        Menu(data: viewModel.backListMenuData) {
          controller.dismiss()
          viewModel.handleBackForwardMenuAction($0)
        }
        .menuStyle(StandardMenuStyle())
        .onAppear {
          viewModel.updateBackListMenuData(colorScheme: colorScheme)
        }
      },
      label: { _ in
        Symbol(source: StandardSymbols.back)
          .tintColor(.primaryText)
      },
      primaryAction: {
        action(.goBack)
      },
    )
    .buttonStyle(.standard)
    .popoverPlacement(.below(alignment: .leading))
    .popoverActivation([.pointerLongPress, .pointerContextPress])
    .disabled(!viewModel.tabModel.canGoBack)
  }

  private var forwardButton: some View {
    PopoverButton(
      content: { controller in
        Menu(data: viewModel.forwardListMenuData) {
          controller.dismiss()
          viewModel.handleBackForwardMenuAction($0)
        }
        .menuStyle(StandardMenuStyle())
        .onAppear {
          viewModel.updateForwardListMenuData(colorScheme: colorScheme)
        }
      },
      label: { _ in
        Symbol(source: StandardSymbols.forward)
          .tintColor(.primaryText)
      },
      primaryAction: {
        action(.goForward)
      },
    )
    .buttonStyle(.standard)
    .popoverPlacement(.below(alignment: .leading))
    .popoverActivation([.pointerLongPress, .pointerContextPress])
    .disabled(!viewModel.tabModel.canGoForward)
  }

  private var reloadStopButton: some View {
    Button(
      action: {
        action(viewModel.tabModel.isLoading ? .stop : .reload)
      },
      label: { _ in
        Symbol(source: viewModel.tabModel.isLoading ? StandardSymbols.stop : StandardSymbols.reload)
          .tintColor(.primaryText)
      }
    )
    .buttonStyle(.standard)
  }

  private var addressBar: some View {
    AddressBarView(viewModel: viewModel.addressBarViewModel) {
      action(.addressBar($0))
    }
  }

  private var recentDownloadsButton: some View {
    PopoverButton(
      content: { controller in
        RecentDownloadsView(viewModel: viewModel.recentDownloadsViewModel) {
          switch $0 {
          case .cancel:
            break
          case .openFile, .openFolder:
            controller.dismiss()
          }
          action(.downloads($0))
        }
      },
      label: { _ in
        Symbol(source: StandardSymbols.download)
          .tintColor(.primaryText)
      }
    )
    .buttonStyle(.standard)
    .popoverPlacement(.below(alignment: .trailing))
  }

  private var menuButton: some View {
    PopoverButton(
      content: { controller in
        MainMenuView {
          controller.dismiss()
          action(.command($0))
        }
      },
      label: { _ in
        Symbol(source: StandardSymbols.menu)
          .tintColor(.primaryText)
      }
    )
    .buttonStyle(.standard)
    .popoverPlacement(.below(alignment: .trailing))
  }

  private var spaceSelectorToggleButton: some View {
    PopoverButton(
      content: { controller in
        SpaceSelectorView(viewModel: viewModel.spaceSelectorViewModel) {
          print(">>> SpaceSelectorView action: \($0)")
          action(.spaceSelector($0))
        }
      },
      label: { _ in
        Symbol(source: StandardSymbols.grid)
          .tintColor(.primaryText)
      }
    )
    .buttonStyle(.standard)
    .popoverPlacement(.below(alignment: .trailing))
    .disabled(viewModel.disableSpaceSelector)
  }

  private var divider: some View {
    Color.primaryText
      .opacity(0.1)
      .height(1)
      .alignment(.bottom)
  }

  private var progressBar: some View {
    Group { geom in
      Group {
        Color.white
        StandardColors.highlight
      }
      .opacity(viewModel.tabModel.isLoading ? 1 : 0)
      .width(geom.width * (viewModel.tabModel.loadingProgress ?? 0))
      .alignment(.leading)
    }
    .height(1.5)
    .alignment(.bottom)
  }

  private func buttonSize(for geom: GeometryProxy) -> CGFloat {
    geom.height
  }

  // TODO: should be centered within outer group actually.

  private func addressBarWidth(for geom: GeometryProxy) -> CGFloat {
    let hasRecentDownloads = !viewModel.recentDownloadsViewModel.isEmpty
    let numButtons = CGFloat(5 + (hasRecentDownloads ? 1 : 0))
    let availableWidth = geom.width - numButtons * buttonSize(for: geom) - (numButtons + 2) * Metrics.buttonPadding
    return min(Metrics.addressBarMaxWidth, availableWidth)
  }

  private func addressBarOffsetX(for geom: GeometryProxy) -> CGFloat {
    let addressBarWidth = addressBarWidth(for: geom)

    // Center relative to the outer geometry.
    let centeredOffsetX
      = (geom.width + viewModel.insets.leading + viewModel.insets.trailing) / 2
      - addressBarWidth / 2
      - viewModel.insets.leading

    // Constrain based on the inner geometry.

    let minOffsetX = 3 * buttonSize(for: geom) + 4 * Metrics.buttonPadding
    if centeredOffsetX < minOffsetX {
      return minOffsetX
    }

    let maxOffsetX = geom.width - addressBarWidth - buttonSize(for: geom) - 2 * Metrics.buttonPadding
    if centeredOffsetX > maxOffsetX {
      return maxOffsetX
    }

    return centeredOffsetX
  }
}
