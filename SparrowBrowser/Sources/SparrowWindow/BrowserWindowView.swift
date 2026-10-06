import Foundation
import SparrowContent
import SparrowContentToolbar
import SparrowDesignSystem
import SparrowSpacesUI
import SparrowTabsUI
import SparrowUI
import SparrowUIFoundation

public struct BrowserWindowView: View {
  public enum Action {
    case quit
    case newWindow
    case newIncognitoWindow
    case close
    case applyColorScheme(ColorScheme?)
    case spaceSelector(SpaceSelectorView.Action)
  }

  public init(viewModel: BrowserWindowViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      backgroundTint

      topTabsView
      sideTabsView
      groupSelectorView
      contentView

      sideTabsControlsView

      #if os(Windows)
      windowControlsView
      #endif

      Group {
        Button(
          action: {
            withAnimation {
              viewModel.cycleTabsStyle()
            }
          },
          label: {
            Text("Cycle Tabs Style!")
          }
        )
        .buttonStyle(.standard)
        .height(32)
        .alignment(.top)

        Button(
          action: {
            withAnimation {
              viewModel.cycleTabsVisibility()              
            }
          },
          label: {
            Text("Cycle Tabs Visibility!")
          }
        )
        .buttonStyle(.standard)
        .height(32)
        .alignment(.bottom)
      }
      .height(64)
      .width(160)
      .alignment(.center)

      IfLet(viewModel.overlayViewModel) {
        BrowserWindowOverlayViewRepresentable(viewModel: $0) {
          viewModel.handleOverlayAction($0).flatMap { action($0) }
        }
      }
    }
    .readSize(to: $size)
    .onChange(of: viewModel.forcedColorScheme) {
      action(.applyColorScheme($0))
    }
    .registerCustomImageSource(viewModel.dependencies.webHistory.faviconImageSource)
    .registerCustomImageSource(viewModel.dependencies.webHistory.pageFaviconImageSource)
    .onChange(of: viewModel.groupModel.tabIDs.isEmpty) {
      if $0 {
        action(.close)
      }
    }
    .onChange(of: (viewModel.overlayViewModel, contentViewInsets)) {
      $0?.contentViewInsets = $1
    }
    .onChange(of: (viewModel.overlayViewModel, viewModel.contentViewModel.toolbarHeight)) {
      $0?.contentToolbarHeight = $1
    }
    #if os(Windows)
    .onChange(of: computeNonClientPassthroughRects()) {
      viewModel.updateNonClientPassthroughRects?($0)
    }
    #endif
  }

  private let viewModel: BrowserWindowViewModel
  private let action: (Action) -> Void

  @State private var size = CGSize.zero
  @State private var sideTabsDesiredWidth: CGFloat?
  @State private var resizingSideTabs = false

  private var backgroundTint: some View {
    Color(light: .blue.opacity(0.05), dark: .black.opacity(0.5))
  }

  private var topTabsView: some View {
    TopTabsView(viewModel: viewModel.topTabsViewModel) {
      viewModel.handleTabsAction($0).flatMap { action($0) }
    }
    .height(viewModel.titleBarHeight)
    .offset(x: topTabsOffsetX, y: topTabsOffsetY)
    .alignment(.top)
  }

  private var sideTabsView: some View {
    Group { geom in
      SideTabsView(viewModel: viewModel.sideTabsViewModel) {
        viewModel.handleTabsAction($0).flatMap { action($0) }
      }
      .height(geom.height - viewModel.titleBarHeight)
      .alignment(.bottom)

      SidebarResizer(tracking: $resizingSideTabs) {
        sideTabsDesiredWidth = (sideTabsDesiredWidth ?? viewModel.sideTabsWidth) + $0
      }
      .height(geom.height - viewModel.titleBarHeight)
      .alignment(.bottomTrailing)
      .onAppear {
        sideTabsDesiredWidth = viewModel.sideTabsWidth
      }
      .onChange(of: sideTabsDesiredWidth) {
        guard let width = $0 else { return }
        viewModel.sideTabsWidth = clamp(width, 0, min(400, size.width))
      }
    }
    .offset(x: sideTabsOffsetX, y: sideTabsOffsetY)
    .width(viewModel.sideTabsWidth)
  }

  private var groupSelectorView: some View {
    Group {
      Color.blue.opacity(0.5)
    }
    .offset(x: groupSelectorOffsetX)
    .width(viewModel.groupSelectorWidth)
  }

  private var sideTabsControlsView: some View {
    Group {
      sideTabsToggleButton
        .alignment(.trailing)
    }
    .offset(x: sideTabsControlsViewOffsetX, y: sideTabsControlsViewOffsetY)
    .width(sideTabsControlsViewWidth)
    .height(viewModel.titleBarHeight)
    .clipped()
    .onChange(of: shouldShowSideTabsToggleButtonOnToolbar) { value in
      guard viewModel.showSideTabsToggleButtonOnToolbar != value else { return }
      if resizingSideTabs {
        viewModel.showSideTabsToggleButtonOnToolbar = value
      } else {
        withAnimation {
          viewModel.showSideTabsToggleButtonOnToolbar = value
        }
      }
    }
  }

  private var sideTabsControlsViewVisibility: Bool {
    if viewModel.tabsStyle == .sideTabs {
      true
    } else if viewModel.tabsVisibility == .visible {
      true
    } else {
      false
    }
  }

  private var contentView: some View {
    Group {
      ContentView(viewModel: viewModel.contentViewModel, action: {
        viewModel.handleContentAction($0).flatMap { action($0) }
      })
      .padding(.leading, contentViewInsets.leading)
      .padding(.trailing, contentViewInsets.trailing)
      .shadow(
        color: StandardColors.shadow.opacity(viewModel.tabsStyle == .sideTabs ? 1 : 0),
        radius: StandardMetrics.shadowRadius,
      )
    }
    .padding(.top, contentViewInsets.top)
    .clipped(viewModel.tabsStyle == .sideTabs)
  }

  private var sideTabsToggleButton: some View {
    Group {
      Button(
        action: {
          withAnimation {
            viewModel.cycleTabsVisibility()
          }
        },
        label: {
          Symbol(source: sideTabsToggleButtonSymbol)
            .tintColor(.primaryText)
        }
      )
      .buttonStyle(.standard)
      .padding(.all, ContentToolbarView.Metrics.buttonPadding)
    }
    .width(viewModel.titleBarHeight)
    .height(viewModel.titleBarHeight)
  }

  private var sideTabsToggleButtonSymbol: SymbolSource {
    #if os(macOS)
    .init(systemName: "rectangle.leadingthird.inset.filled", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e90c}", size: 12) // DockLeft
    #endif
  }

  private var topTabsOffsetX: CGFloat {
    if viewModel.tabsStyle == .sideTabs {
      viewModel.sideTabsWidth
    } else {
      0
    }
  }

  private var topTabsOffsetY: CGFloat {
    if viewModel.tabsStyle == .sideTabs || viewModel.tabsVisibility == .hidden {
      -viewModel.titleBarHeight
    } else {
      0
    }
  }

  private var sideTabsOffsetX: CGFloat {
    if viewModel.tabsStyle == .topTabs || viewModel.tabsVisibility == .hidden {
      -viewModel.sideTabsWidth
    } else {
      0
    }
  }

  private var sideTabsOffsetY: CGFloat {
    if viewModel.tabsStyle == .topTabs, viewModel.tabsVisibility == .visible {
      viewModel.titleBarHeight
    } else {
      0
    }
  }

  private var sideTabsControlsViewOffsetX: CGFloat {
    contentViewInsets.leading
      + viewModel.contentViewModel.contentToolbarViewModel.insets.leading
      - sideTabsControlsViewWidth
      + (viewModel.showSideTabsToggleButtonOnToolbar ? ContentToolbarView.Metrics.buttonPadding : 0)
  }

  private var sideTabsControlsViewOffsetY: CGFloat {
    contentViewInsets.top
  }

  private var sideTabsControlsViewWidth: CGFloat {
    if viewModel.tabsStyle == .sideTabs {
      viewModel.titleBarHeight
    } else {
      0
    }
  }

  private var groupSelectorOffsetX: CGFloat {
    size.width - (viewModel.groupSelectorIsVisible ? viewModel.groupSelectorWidth : 0)
  }

  private var contentViewInsets: EdgeInsets {
    if viewModel.tabsVisibility == .hidden {
      .init(
        leading: 0,
        trailing: contentViewTrailingInsets,
        top: 0,
        bottom: 0,
      )
    } else {
      switch viewModel.tabsStyle {
      case .topTabs:
        .init(
          leading: 0,
          trailing: contentViewTrailingInsets,
          top: viewModel.titleBarHeight,
          bottom: 0,
        )
      case .sideTabs:
        .init(
          leading: viewModel.sideTabsWidth,
          trailing: contentViewTrailingInsets,
          top: 0,
          bottom: 0,
        )
      }
    }
  }

  private var contentViewTrailingInsets: CGFloat {
    viewModel.groupSelectorIsVisible ? viewModel.groupSelectorWidth : 0
  }

  #if os(Windows)
  private var windowControlsView: some View {
    Group {
      Button(action: {}, label: {
        Symbol(source: .init(glyph: "\u{E921}", size: 10))
          .tintColor(.primaryText)
      })
      .buttonStyle(StandardButtonStyle(cornerRadius: 0))
      .width(viewModel.titleBarHeight)

      Button(action: {}, label: {
        Symbol(source: .init(glyph: "\u{E922}", size: 10)) // TODO: Or e923 when already maximized
          .tintColor(.primaryText)
      })
      .buttonStyle(StandardButtonStyle(cornerRadius: 0))
      .width(viewModel.titleBarHeight)
      .offset(x: viewModel.titleBarHeight)

      Button(action: {}, label: { config in
        Symbol(source: .init(glyph: "\u{E8bb}", size: 10))
          .tintColor(config.isHovered ? .white : .primaryText)
      })
      .buttonStyle(StandardButtonStyle(cornerRadius: 0, backgroundColor: .red))
      .width(viewModel.titleBarHeight)
      .offset(x: 2 * viewModel.titleBarHeight)
    }
    .width(3 * viewModel.titleBarHeight)
    .height(viewModel.titleBarHeight)
    .alignment(.topTrailing)
  }
  #endif

  private var shouldShowSideTabsToggleButtonOnToolbar: Bool {
    guard viewModel.tabsStyle == .sideTabs else { return false }
    return if viewModel.sideTabsWidth < (viewModel.titleBarInsets.leading + viewModel.titleBarHeight) {
      true
    } else if viewModel.tabsVisibility == .hidden {
      true
    } else {
      false
    }
  }

  #if os(Windows)
  private func computeNonClientPassthroughRects() -> [CGRect] {
    if viewModel.tabsStyle == .topTabs, viewModel.tabsVisibility == .visible {
      viewModel.topTabsViewModel.nonClientPassthroughRects
    } else {
      []
    }
  }
  #endif
}