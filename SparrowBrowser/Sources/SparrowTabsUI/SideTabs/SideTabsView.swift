import Foundation
import OrderedCollections
import SparrowDesignSystem
import SparrowTabs
import SparrowUI

public struct SideTabsView: View {
  public init(
    viewModel: SideTabsViewModel,
    action: @escaping (TabsAction) -> Void,
  ) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      newTabButton
        .padding(tabContentInsets)
        .height(viewModel.tabHeight - tabContentInsets.totalVertical)

      Group {
        Repeated(visibleTabs, id: \.key) { (tabID, tabViewModel) in
          tabBackgroundView(for: tabViewModel)
            .height(height(for: tabViewModel))
            .offset(x: 0, y: offsetY(for: tabID))
        }

        Repeated(visibleTabs, id: \.key) { (tabID, tabViewModel) in
          tabView(for: tabViewModel)
            .height(height(for: tabViewModel))
            .offset(y: (tabViewModel === viewModel.draggedTabViewModel ? draggedTabOffsetY : nil) ?? offsetY(for: tabID))
        }

        selectedTabView
      }
      .padding(.top, viewModel.tabHeight)
      .clipped(scrollOffset != 0)
      .readSize(to: $viewPortSize)
      .onPointerWheel {
        // TODO: Add rubberbanding (or maybe best done by overlaying a NSScrollView).
        scrollOffset = clampedScrollOffset(scrollOffset - $0.delta.y)
      }
      .onChange(of: viewPortSize) { _ in
        scrollOffset = clampedScrollOffset(scrollOffset)
      }
      .onChange(of: scrollOffset) { _ in
        updateDragPosition()
      }
    }
    .clipped()
    .onChange(of: viewModel.groupModel.tabIDs) {
      viewModel.updateTabViewModels(for: $0)
    }
  }

  private enum Metrics {
    static let padding: CGFloat = 6
  }

  private let viewModel: SideTabsViewModel
  private let action: (TabsAction) -> Void

  @State private var viewPortSize = CGSize.zero
  @State private var scrollOffset = CGFloat.zero
  @State private var newTabSymbolSize = CGSize.zero
  @State private var dragTabID: TabID?
  @State private var dragOriginY: CGFloat?

  private var visibleTabs: [(key: TabID, value: TabViewModel)] {
    let visibleMinY = scrollOffset
    let visibleMaxY = scrollOffset + viewPortSize.height

    let visibleStartIndex = Int(visibleMinY / viewModel.tabHeight)
    let visibleEndIndex = Int(visibleMaxY / viewModel.tabHeight)

    let lowerBound = min(viewModel.tabViewModels.count, max(0, visibleStartIndex))
    let upperBound = min(viewModel.tabViewModels.count, visibleEndIndex + 1)
    let range = Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))

    var result = range.map {
      viewModel.tabViewModels.elements[$0]
    }
    // Keep the pointer's tab alive even when reordering or scrolling moves its slot offscreen.
    if let draggedTab = viewModel.draggedTabViewModel,
      !result.contains(where: { $0.key == draggedTab.tabID })
    {
      result.append((key: draggedTab.tabID, value: draggedTab))
    }
    return result
  }

  private var tabContentInsets: EdgeInsets {
    .init(
      leading: Metrics.padding,
      trailing: Metrics.padding,
      top: Metrics.padding / 2,
      bottom: Metrics.padding / 2,
    )
  }

  private var newTabButton: some View {
    Button {
      withAnimation {
        action(.newTab)
      }
    } label: { _ in
      // TODO: Looks like a use case for HStack!
      Group {
        Symbol(source: StandardSymbols.newTab)
          .tintColor(.primaryText)
          .alignment(.leading)
          .readSize(to: $newTabSymbolSize)

        Text("New Tab")
          .font(TabView.Metrics.titleFont)
          .alignment(.leading)
          .padding(.leading, newTabSymbolSize.width + TabView.Metrics.intraContentPadding)
      }
      .padding(.horizontal, TabView.Metrics.intraContentPadding)
    }
    .buttonStyle(.standard)
  }

  private var tabVisor: some View {
    RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius)
      .fill(.primaryBackground)
      // .stroke(.primaryText.opacity(0.2))
      .shadow(color: StandardColors.shadow, radius: StandardMetrics.shadowRadius)
      .height(viewModel.tabHeight - Metrics.padding)
      .padding(.horizontal, Metrics.padding)
      .padding(.vertical, Metrics.padding / 2)
  }

  private var selectedTabView: some View {
    IfLet(viewModel.selectedTabViewModel, id: \.tabID) { tabViewModel in
      Group {
        tabVisor
        tabView(for: tabViewModel)
          .height(height(for: tabViewModel))
      }
      .offset(y: draggedTabOffsetY ?? offsetY(for: tabViewModel.tabID))
    }
    .onChange(of: viewModel.draggedTabViewModel) { tabViewModel in
      guard dragTabID != tabViewModel?.tabID else { return }
      dragTabID = tabViewModel?.tabID
      dragOriginY = tabViewModel.map { offsetY(for: $0.tabID) }
    }
    .onChange(of: viewModel.draggedTabViewModel?.dragOffset?.y) { _ in
      updateDragPosition()
    }
  }

  private var draggedTabOffsetY: CGFloat? {
    guard let tabViewModel = viewModel.draggedTabViewModel,
      let dragOffset = tabViewModel.dragOffset,
      let dragOriginY
    else { return nil }

    let lastTabOffset = CGFloat(max(0, viewModel.tabViewModels.count - 1)) * viewModel.tabHeight
    return clamp(dragOriginY + dragOffset.y, -scrollOffset, lastTabOffset - scrollOffset)
  }

  private var isDraggingTab: Bool {
    viewModel.draggedTabViewModel != nil
  }

  private func updateDragPosition() {
    guard let tabViewModel = viewModel.draggedTabViewModel,
      let draggedTabOffsetY
    else { return }

    let dragRect = CGRect(x: 0, y: draggedTabOffsetY, width: 10, height: viewModel.tabHeight)
    for tabID in viewModel.tabViewModels.keys {
      guard tabID != tabViewModel.tabID else { continue }
      let tabRect = CGRect(x: 0, y: offsetY(for: tabID), width: 10, height: viewModel.tabHeight)
      let intersection = tabRect.intersection(dragRect)
      if !intersection.isNull, intersection.height > tabRect.height / 2 {
        viewModel.handleDrag(of: tabViewModel.tabID, toPositionOf: tabID)
        return
      }
    }
  }

  private func tabBackgroundView(for tabViewModel: TabViewModel) -> some View {
    Group { geom in
      TabBackgroundView(
        viewModel: tabViewModel,
        contentAlignment: .top,
        contentInsets: tabContentInsets,
        intendedSize: geom.size,
        allowHoverEffects: !isDraggingTab && !tabViewModel.isSelected,
      )
    }
  }

  private func tabView(for tabViewModel: TabViewModel) -> some View {
    Group { geom in
      TabView(
        viewModel: tabViewModel,
        contentAlignment: .top,
        contentInsets: tabContentInsets,
        intendedSize: geom.size,
        options: isDraggingTab ? [.noCloseButton] : [],
        action: { handleTabAction($0, for: tabViewModel.tabID) },
      )
    }
  }

  private func handleTabAction(_ action: TabView.Action, for tabID: TabID) {
    withAnimation {
      self.action(.tab(action, for: tabID))
    }
  }

  private func clampedScrollOffset(_ scrollOffset: CGFloat) -> CGFloat {
    let count = viewModel.tabViewModels.count
    let maxScrollOffset = CGFloat(count) * viewModel.tabHeight - viewPortSize.height
    return max(0, min(maxScrollOffset, scrollOffset))
  }

  private func offsetY(for tabID: TabID) -> CGFloat {
    let index = viewModel.tabViewModels.keys.firstIndex(of: tabID) ?? 0
    return viewModel.tabHeight * CGFloat(index) - scrollOffset
  }

  private func height(for tabViewModel: TabViewModel) -> CGFloat {
    tabViewModel.isExpanded ? viewModel.tabHeight : 0
  }
}
