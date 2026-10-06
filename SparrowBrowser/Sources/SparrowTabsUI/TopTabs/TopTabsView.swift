import Foundation
import SparrowDesignSystem
import SparrowTabs
import SparrowUI

public struct TopTabsView: View {
  public enum Metrics {
    public static let padding: CGFloat = 6
    static let maxTabWidth: CGFloat = 150
    static let dividerWidth: CGFloat = 1
  }

  public init(viewModel: TopTabsViewModel, action: @escaping (TabsAction) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      Repeated(viewModel.tabViewModels.elements, id: \.key) { (tabID, tabViewModel) in
        Group {
          TabBackgroundView(
            viewModel: tabViewModel,
            contentAlignment: .leading,
            contentInsets: tabContentInsets,
            intendedSize: tabSize,
            allowHoverEffects: !isDraggingTab && !tabViewModel.isSelected,
          )
          .padding(.top, Metrics.padding)

          StandardColors.border
            .width(Metrics.dividerWidth)
            .offset(x: Metrics.dividerWidth / 2)
            .alignment(.trailing)
            .padding(.vertical, 2 * Metrics.padding)
            .opacity(showDivider(for: tabID) ? 1 : 0)
        }
        .width(layout.width(for: tabID))
        .offset(x: layout.offset(for: tabID))
      }

      tabVisor()

      Repeated(viewModel.tabViewModels.elements, id: \.key) { (tabID, tabViewModel) in
        TabView(
          viewModel: tabViewModel,
          contentAlignment: .leading,
          contentInsets: tabContentInsets,
          intendedSize: tabSize,
          options: isDraggingTab ? [.noCloseButton] : [],
          action: { handleTabAction($0, for: tabID) },
        )
        .padding(.top, Metrics.padding)
        .width(layout.width(for: tabID))
        .offset(x: (tabViewModel === viewModel.draggedTabViewModel ? draggedTabOffsetX : nil) ?? layout.offset(for: tabID))
      }

      newTabButton
        .padding(.top, Metrics.padding)
        .padding(.bottom, Metrics.padding)
        .width(layout.newTabButtonWidth)
        .offset(x: layout.newTabButtonOffset)

      selectedTabView
    }
    .onChange(of: viewModel.groupModel.tabIDs) {
      viewModel.updateTabViewModels(for: $0)
    }
    .onChange(of: computeLayout()) {
      layout = $0
    }
    #if os(Windows)
    .onChange(of: computeNonClientPassthroughRects()) {
      viewModel.nonClientPassthroughRects = $0
    }
    #endif
    .readSize(to: $size)
  }

  @MainActor
  private struct TabLayout {
    let offset: CGFloat
    let width: CGFloat
  }

  @MainActor
  private struct Layout {
    let defaultTabWidth: CGFloat
    let tabs: [TabID: TabLayout]
    let tabVisorOffset: CGFloat
    let tabVisorWidth: CGFloat
    let newTabButtonOffset: CGFloat
    let newTabButtonWidth: CGFloat

    func width(for tabID: TabID) -> CGFloat {
      tabs[tabID]?.width ?? 0
    }

    func offset(for tabID: TabID) -> CGFloat {
      tabs[tabID]?.offset ?? 0
    }

    static var zero = Layout(
      defaultTabWidth: 0,
      tabs: [:],
      tabVisorOffset: 0,
      tabVisorWidth: 0,
      newTabButtonOffset: 0,
      newTabButtonWidth: 0,
    )
  }

  private let viewModel: TopTabsViewModel
  private let action: (TabsAction) -> Void

  @State private var layout = Layout.zero
  @State private var size = CGSize.zero
  @State private var dragTabID: TabID?
  @State private var dragOriginX: CGFloat?
  @State private var newTabButtonIsHovered = false

  private func tabVisor(with options: TopTabsVisorView.Options = []) -> some View {
    Group {
      TopTabsVisorView(
        offset: draggedTabOffsetX ?? layout.tabVisorOffset,
        width: layout.tabVisorWidth,
        options: options,
      )
      .padding(.top, Metrics.padding / 2)
    }
    .clipped()
  }

  private var selectedTabView: some View {
    Group {
      Color.primaryBackground
      IfLet(viewModel.selectedTabViewModel, id: \.tabID) { tabViewModel in
        TabView(
          viewModel: tabViewModel,
          contentAlignment: .leading,
          contentInsets: tabContentInsets,
          intendedSize: tabSize,
          options: [],
          action: { handleTabAction($0, for: tabViewModel.tabID) },
        )
        .padding(.top, Metrics.padding)
        .width(layout.width(for: tabViewModel.tabID))
        .offset(x: draggedTabOffsetX ?? layout.offset(for: tabViewModel.tabID))
        .onChange(of: tabViewModel.dragOffset?.x) { dragOffsetX in
          guard let dragOffsetX else { return }

          let targetOffsetX = dragOffsetX + (dragOriginX ?? 0)
          let dragRect = CGRect(x: targetOffsetX, y: 0, width: layout.width(for: tabViewModel.tabID), height: 10)

          let targetTabID: TabID? = {
            for (tabID, tabLayout) in layout.tabs {
              let tabRect = CGRect(x: tabLayout.offset, y: 0, width: tabLayout.width, height: 10)
              let intersection = tabRect.intersection(dragRect)
              if !intersection.isNull, intersection.width > (tabRect.width / 2) {
                return tabID
              }
            }
            return nil
          }()
          guard let targetTabID, targetTabID != tabViewModel.tabID else { return }

          viewModel.handleDrag(of: tabViewModel.tabID, toPositionOf: targetTabID)
        }
      }
    }
    .mask(tabVisor(with: [.noBorder, .noShadow]))
    .onChange(of: viewModel.draggedTabViewModel) { tabViewModel in
      guard dragTabID != tabViewModel?.tabID else { return }
      dragTabID = tabViewModel?.tabID
      dragOriginX = tabViewModel.flatMap { layout.offset(for: $0.tabID) }
    }
  }

  private var newTabButton: some View {
    Button {
      action(.newTab)
    } label: { _ in
      Symbol(source: StandardSymbols.newTab)
        .tintColor(.primaryText)
    }
    .buttonStyle(.standard)
    .onPointerEntered {
      newTabButtonIsHovered = true
    }
    .onPointerExited {
      newTabButtonIsHovered = false
    }
  }

  private var tabContentInsets: EdgeInsets {
    .init(
      leading: Metrics.padding / 2,
      trailing: Metrics.padding / 2,
      top: 0,
      bottom: Metrics.padding,
    )
  }

  private var tabSize: CGSize {
    .init(width: layout.defaultTabWidth, height: size.height - Metrics.padding)
  }

  private var newTabButtonWidth: CGFloat {
    size.height - 2 * Metrics.padding
  }

  private var newTabButtonOffset: CGFloat {
    tabOffset(forIndex: viewModel.tabViewModels.count) + Metrics.padding / 2
  }

  private var tabVisorWidth: CGFloat {
    guard let selectedTabViewModel = viewModel.selectedTabViewModel else { return 0 }
    return tabWidth(for: selectedTabViewModel)
  }

  private var tabVisorOffset: CGFloat {
    guard let selectedTabViewModel = viewModel.selectedTabViewModel else { return 0 }
    return tabOffset(for: selectedTabViewModel.tabID)
  }

  private var draggedTabOffsetX: CGFloat? {
    guard
      let tabViewModel = viewModel.draggedTabViewModel,
      let dragOffset = tabViewModel.dragOffset,
      let dragOriginX
    else {
      return nil
    }
    let proposal = dragOffset.x + dragOriginX
    return clamp(proposal, viewModel.insets.leading, tabOffset(forIndex: viewModel.tabViewModels.count - 1))
  }

  private var isDraggingTab: Bool {
    viewModel.tabViewModels.values.contains(where: \.isDragging)
  }

  private var defaultTabWidth: CGFloat {
    let numTabs = viewModel.lockedTabCount ?? viewModel.tabViewModels.values.count { $0.isExpanded }
    return defaultTabWidth(forNumTabs: numTabs)
  }

  private func defaultTabWidth(forNumTabs numTabs: Int) -> CGFloat {
    let availableWidth = size.width
      - viewModel.insets.leading
      - viewModel.insets.trailing
      - newTabButtonWidth
      - Metrics.padding
      - Metrics.padding / 2
    let availableWidthPerTab = availableWidth / CGFloat(numTabs)
    return min(Metrics.maxTabWidth, availableWidthPerTab)
  }

  private func tabWidth(for tabViewModel: TabViewModel) -> CGFloat {
    tabViewModel.isExpanded ? defaultTabWidth : 0
  }

  private func tabOffset(for tabID: TabID) -> CGFloat {
    let index = viewModel.tabViewModels.keys.firstIndex(of: tabID) ?? 0
    return tabOffset(forIndex: index)
  }

  private func tabOffset(forIndex index: Int) -> CGFloat {
    var offset = viewModel.insets.leading
    for i in 0..<index {
      offset += tabWidth(for: viewModel.tabViewModels.values[i])
    }
    return offset
  }

  private func computeLayout() -> Layout {
    let tabsLayout: [TabID: TabLayout] = .init(uniqueKeysWithValues: viewModel.tabViewModels.values.map {
      let tabLayout = TabLayout(
        offset: tabOffset(for: $0.tabID),
        width: tabWidth(for: $0),
      )
      return ($0.tabID, tabLayout)
    })

    return .init(
      defaultTabWidth: defaultTabWidth,
      tabs: tabsLayout,
      tabVisorOffset: tabVisorOffset,
      tabVisorWidth: tabVisorWidth,
      newTabButtonOffset: newTabButtonOffset,
      newTabButtonWidth: newTabButtonWidth,
    )
  }

  private func showDivider(for tabID: TabID) -> Bool {
    guard let indexOfTab = viewModel.groupModel.tabIDs.firstIndex(of: tabID) else {
      return false
    }

    guard let indexOfSelectedTab = viewModel.groupModel.tabIDs.firstIndex(of: viewModel.selectedTabID) else {
      return false
    }

    if indexOfTab == indexOfSelectedTab || indexOfTab == (indexOfSelectedTab - 1) {
      return false
    }

    if viewModel.tabViewModels[tabID]?.isHovered == true {
      return false
    }

    if
      indexOfTab < (viewModel.groupModel.tabIDs.count - 1),
      viewModel.tabViewModels[viewModel.groupModel.tabIDs[indexOfTab + 1]]?.isHovered == true
    {
      return false
    }

    if newTabButtonIsHovered, indexOfTab == (viewModel.groupModel.tabIDs.count - 1) {
      return false
    }

    return true
  }

  private func handleTabAction(_ action: TabView.Action, for tabID: TabID) {
    self.action(.tab(action, for: tabID))
  }

  #if os(Windows)
  private func computeNonClientPassthroughRects() -> [CGRect] {
    var result = [CGRect]()
    for (tabID, tabLayout) in layout.tabs {
      let yOffset = tabID == viewModel.selectedTabID ? 0 : Metrics.padding
      result.append(.init(
        x: tabLayout.offset,
        y: yOffset,
        width: tabLayout.width,
        height: size.height - yOffset,
      ))
    }
    // NOTE: No need to exclude the new tab button as its action occurs on pointer up.
    // result.append(.init(
    //   x: layout.newTabButtonOffset,
    //   y: Metrics.padding,
    //   width: layout.newTabButtonWidth,
    //   height: size.height - 2 * Metrics.padding,
    // ))
    return result
  }
  #endif
}