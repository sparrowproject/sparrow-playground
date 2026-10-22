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

      Group {
        backButton
          .width(layout.buttonWidth)
          .offset(x: layout.backButtonOffsetX)

        forwardButton
          .width(layout.buttonWidth)
          .offset(x: layout.forwardButtonOffsetX)

        reloadStopButton
          .width(layout.buttonWidth)
          .offset(x: layout.reloadStopButtonOffsetX)

        addressBar
          .offset(x: layout.addressBarOffsetX)
          .width(layout.addressBarWidth)

        recentDownloadsButton
          .width(layout.buttonWidth)
          .offset(x: layout.recentDownloadsButtonOffsetX)
          .visible(!viewModel.recentDownloadsViewModel.isEmpty)

        #if !os(macOS)
        menuButton
          .width(layout.buttonWidth)
          .offset(x: layout.menuButtonOffsetX)
        #endif
        
        spaceSelectorToggleButton
          .width(layout.buttonWidth)
          .offset(x: layout.spaceSelectorButtonOffsetX)
      }
      .padding(.vertical, Metrics.buttonPadding)
      .padding(viewModel.insets)
      .readSize(to: $contentSize)

      divider
      progressBar
    }
    .onChange(of: computeLayout()) { newLayout in
      if layout != newLayout {
        layout = newLayout
      }
    }
    .onChange(of: viewModel.tabModel.url, perform: viewModel.handleURLChanged)
    .onChange(
      of: viewModel.recentDownloadsViewModel.hasPendingDownloads,
      perform: {
        if $0 {
          withAnimation {
            recentDownloadsNeedsOpen = true
          }
        }
      }
    )
    .readColorScheme(to: $colorScheme)
  }

  private struct Layout: Equatable {
    let buttonWidth: CGFloat

    let backButtonOffsetX: CGFloat
    let forwardButtonOffsetX: CGFloat
    let reloadStopButtonOffsetX: CGFloat

    let addressBarWidth: CGFloat
    let addressBarOffsetX: CGFloat

    let recentDownloadsButtonOffsetX: CGFloat
    let menuButtonOffsetX: CGFloat
    let spaceSelectorButtonOffsetX: CGFloat

    static let zero = Layout(
      buttonWidth: 0,
      backButtonOffsetX: 0,
      forwardButtonOffsetX: 0,
      reloadStopButtonOffsetX: 0,
      addressBarWidth: 0,
      addressBarOffsetX: 0,
      recentDownloadsButtonOffsetX: 0,
      menuButtonOffsetX: 0,
      spaceSelectorButtonOffsetX: 0,
    )
  }

  private let viewModel: ContentToolbarViewModel
  private let action: (Action) -> Void
  @State private var contentSize = CGSize.zero
  @State private var layout = Layout.zero
  @State private var colorScheme: ColorScheme = .light
  @State private var recentDownloadsNeedsOpen = false

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
        .onAppear {
          recentDownloadsNeedsOpen = false
        }
      },
      label: { _ in
        Symbol(source: StandardSymbols.download)
          .tintColor(.primaryText)
      }
    )
    .buttonStyle(StandardButtonStyle(backgroundColor: recentDownloadsNeedsOpen ? StandardColors.highlightFill : StandardColors.hoverBackground))
    .popoverPlacement(.below(alignment: .trailing))
    .highlightBox(when: recentDownloadsNeedsOpen)
  }

  #if !os(macOS)
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
  #endif

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

  private func computeLayout() -> Layout {
    let buttonWidth: CGFloat = contentSize.height

    let backButtonOffsetX = Metrics.buttonPadding
    let forwardButtonOffsetX = 2 * Metrics.buttonPadding + layout.buttonWidth
    let reloadStopButtonOffsetX = 3 * Metrics.buttonPadding + 2 * layout.buttonWidth

    let addressBarWidth = computeAddressBarWidth(buttonWidth: buttonWidth)
    let addressBarOffsetX = computeAddressBarOffsetX(addressBarWidth: addressBarWidth, buttonWidth: buttonWidth)

    #if os(macOS)
    let hasMenuButton = false
    #else
    let hasMenuButton = true
    #endif

    let recentDownloadsButtonOffsetX = contentSize.width - (2 + (hasMenuButton ? 1 : 0)) * (Metrics.buttonPadding + layout.buttonWidth)
    let menuButtonOffsetX = hasMenuButton ? contentSize.width - 2 * (Metrics.buttonPadding + layout.buttonWidth) : 0
    let spaceSelectorButtonOffsetX = contentSize.width - (Metrics.buttonPadding + layout.buttonWidth)

    return .init(
      buttonWidth: buttonWidth,
      backButtonOffsetX: backButtonOffsetX,
      forwardButtonOffsetX: forwardButtonOffsetX,
      reloadStopButtonOffsetX: reloadStopButtonOffsetX,
      addressBarWidth: addressBarWidth,
      addressBarOffsetX: addressBarOffsetX,
      recentDownloadsButtonOffsetX: recentDownloadsButtonOffsetX,
      menuButtonOffsetX: menuButtonOffsetX,
      spaceSelectorButtonOffsetX: spaceSelectorButtonOffsetX,
    )
  }

  private func computeAddressBarWidth(buttonWidth: CGFloat) -> CGFloat {
    var trailingButtonCount: Int = 1

    if !viewModel.recentDownloadsViewModel.isEmpty {
      trailingButtonCount += 1
    }

    #if !os(macOS)
    // The menu button is not shown on macOS.
    trailingButtonCount += 1
    #endif

    let numButtons = CGFloat(3 + trailingButtonCount)
    let availableWidth = contentSize.width - numButtons * buttonWidth - (numButtons + 2) * Metrics.buttonPadding
    return min(Metrics.addressBarMaxWidth, availableWidth)
  }

  private func computeAddressBarOffsetX(addressBarWidth: CGFloat, buttonWidth: CGFloat) -> CGFloat {
    // Center relative to the outer geometry.
    let centeredOffsetX
      = (contentSize.width + viewModel.insets.leading + viewModel.insets.trailing) / 2
      - addressBarWidth / 2
      - viewModel.insets.leading

    // Constrain based on the inner geometry.

    let minOffsetX = 3 * buttonWidth + 4 * Metrics.buttonPadding
    if centeredOffsetX < minOffsetX {
      return minOffsetX
    }

    let maxOffsetX = contentSize.width - addressBarWidth - buttonWidth - 2 * Metrics.buttonPadding
    if centeredOffsetX > maxOffsetX {
      return maxOffsetX
    }

    return centeredOffsetX
  }
}
