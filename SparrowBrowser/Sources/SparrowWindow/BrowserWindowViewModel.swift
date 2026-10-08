import Foundation
import Observation
import SparrowAddressBar
import SparrowCommands
import SparrowContent
import SparrowContentToolbar
import SparrowDownloads
import SparrowDownloadsUI
import SparrowProfileModel
import SparrowTabs
import SparrowTabsUI
import SparrowToolbelt
import SparrowUI
import SparrowUICore
import SparrowUIFoundation
import SparrowWeb

#if os(macOS)
import AppKit
#endif

public typealias BrowserWindowViewModelDependencies
  = BrowserWindowOverlayViewModelDependencies
  & ContentViewModelDependencies
  & DownloadsManagerProviding
  & ProfileIDProviding
  & SideTabsViewModelDependencies
  & TabSystemProviding
  & TopTabsViewModelDependencies
  & WebHistoryProviding

@Observable @MainActor
public final class BrowserWindowViewModel {
  enum TabsVisibility: Equatable {
    case visible
    case hidden
  }

  public init(
    dependencies: BrowserWindowViewModelDependencies,
    groupModel: Handle<TabGroupModel>,
  ) {
    self.dependencies = dependencies
    self.groupModel = groupModel
    contentViewModel = .init(dependencies: dependencies, groupModel: groupModel)
    topTabsViewModel = .init(dependencies: dependencies, groupModel: groupModel)
    sideTabsViewModel = .init(dependencies: dependencies, groupModel: groupModel)

    print(">>> BrowserWindowViewModel created @ \(ObjectIdentifier(self))")
  }

  deinit {
    print(">>> BrowserWindowViewModel destroyed @ \(ObjectIdentifier(self))")
  }

  public let dependencies: BrowserWindowViewModelDependencies
  public let groupModel: Handle<TabGroupModel>

  public func handleCommand(_ commandID: SparrowCommand.ID) -> BrowserWindowView.Action? {
    return handleCommand(commandID, for: groupModel.selectedTabModel.id)
  }

  let contentViewModel: ContentViewModel
  let topTabsViewModel: TopTabsViewModel
  let sideTabsViewModel: SideTabsViewModel

  // Non-nil if the overlay should be presented.
  private(set) var overlayViewModel: BrowserWindowOverlayViewModel?

  var titleBarInsets: EdgeInsets = .zero {
    didSet {
      guard titleBarInsets != oldValue else { return }
      updateTopTabsInsets()
      updateContentToolbarEdgeInsets()
    }
  }

  var titleBarHeight: CGFloat = .zero {
    didSet {
      guard titleBarHeight != oldValue else { return }

      contentViewModel.toolbarHeight = titleBarHeight
      sideTabsViewModel.tabHeight = titleBarHeight
    }
  }

  var sideTabsWidth: CGFloat = 200 { // TODO: Invent @Setting for this so it can be remembered, or make part of storage?
    didSet {
      guard sideTabsWidth != oldValue else { return }
      updateContentToolbarEdgeInsets()
    }
  }

  var groupSelectorWidth: CGFloat = 40 {
    didSet {
      guard groupSelectorWidth != oldValue else { return }
      updateTopTabsInsets()
    }
  }

  var groupSelectorIsVisible = false {
    didSet {
      guard groupSelectorIsVisible != oldValue else { return }
      updateTopTabsInsets()
    }
  }

  var showSideTabsToggleButtonOnToolbar = false {
    didSet {
      guard showSideTabsToggleButtonOnToolbar != oldValue else { return }
      updateContentToolbarEdgeInsets()
    }
  }
  
  var tabsStyle = TabsStyle.topTabs {
    didSet {
      guard tabsStyle != oldValue else { return }
      updateContentToolbarEdgeInsets()

      dependencies.tabSystem.policy(forGroup: groupModel.id).insertionMode =
        switch tabsStyle {
        case .topTabs:
          .append
        case .sideTabs:
          .prepend
        }
    }
  }

  var tabsVisibility = TabsVisibility.visible {
    didSet {
      guard tabsVisibility != oldValue else { return }
      updateContentToolbarEdgeInsets()
    }
  }

  var forcedColorScheme: ColorScheme? {
    (dependencies.profileID.kind == .incognito) ? .dark : nil
  }

  #if os(Windows)
  var updateNonClientPassthroughRects: (([CGRect]) -> Void)?
  #endif

  func cycleTabsStyle() {
    tabsStyle =
      switch tabsStyle {
      case .topTabs:
        .sideTabs
      case .sideTabs:
        .topTabs
      }
  }

  func cycleTabsVisibility() {
    tabsVisibility =
      switch tabsVisibility {
      case .visible:
        .hidden
      case .hidden:
        .visible
      }
  }

  func handleTabsAction(_ action: TabsAction) -> BrowserWindowView.Action? {
    switch action {
    case .newTab:
      makeNewTab()
    case .tab(let tabAction, let tabID):
      return handleTabAction(tabAction, for: tabID)
    }
    return nil
  }

  func handleContentAction(_ action: ContentView.Action) -> BrowserWindowView.Action? {
    switch action {
    case .toolbar(.goBack):
      selectedTab?.webContent.goBack()
    case .toolbar(.goForward):
      selectedTab?.webContent.goForward()
    case .toolbar(.reload):
      selectedTab?.webContent.reload()
    case .toolbar(.stop):
      selectedTab?.webContent.stop()
    case .toolbar(.command(let commandID)):
      return handleCommand(commandID)
    case .toolbar(.addressBar(let addressBarAction)):
      return handleAddressBarAction(addressBarAction)
    case .toolbar(.spaceSelector(let spaceSelectorAction)):
      return .spaceSelector(spaceSelectorAction)
    case .toolbar(.downloads(let downloadsAction)):
      handleDownloadsAction(downloadsAction)
    }
    return nil
  }

  func handleOverlayAction(_ action: BrowserWindowOverlayView.Action) -> BrowserWindowView.Action? {
    switch action {
    case .addressBarEditor(let addressBarEditorAction):
      handleAddressBarEditorAction(addressBarEditorAction)
    case .spaceSelector(let spaceSelectorAction):
      .spaceSelector(spaceSelectorAction)
    }
  }

  private let clock = ContinuousClock()
  private var timeSinceLastSelectTabCommand: ContinuousClock.Instant?

  private var animationForSelectTab: CoreViewAnimation? {
    let now = ContinuousClock.now
    defer {
      timeSinceLastSelectTabCommand = now
    }
    if let timeSinceLastSelectTabCommand {
      if now - timeSinceLastSelectTabCommand > .milliseconds(200) {
        return .default
      } else {
        return nil
      }
    } else {
      return .default
    }
  }

  private var selectedTabID: TabID? {
    let tabID = groupModel.selectedTabModel.id
    return tabID == .invalid ? nil : tabID
  }

  private var selectedTab: LiveTab? {
    print(">>> BrowserWindowViewModel.selectedTab:")
    return dependencies.tabSystem.liveTab(forTab: groupModel.selectedTabModel.value)
  }

  private var newTabNavigation: TabNavigation {
    .init(url: URL(string: "https://google.com/")!)
  }

  private func handleTabAction(_ action: TabView.Action, for tabID: TabID) -> BrowserWindowView.Action? {
    switch action {
    case .select:
      withAnimation {
        dependencies.tabSystem.select(tab: tabID)
      }
    case .close:
      withAnimation {
        dependencies.tabSystem.remove(tab: tabID)
      }
    case .command(let commandID):
      return handleCommand(commandID, for: tabID)
    }
    return nil
  }

  private func handleCommand(_ commandID: SparrowCommand.ID, for tabID: TabID) -> BrowserWindowView.Action? {
    switch commandID {
    case .quit:
      return .quit
    case .openLocation:
      focusAddressBarEditor(blank: false)
    case .newTab:
      makeNewTab()
    case .newWindow:
      return .newWindow
    case .newIncognitoWindow:
      return .newIncognitoWindow
    case .newTabAfter:
      makeNewTab(after: tabID)
    case .reloadTab:
      dependencies.tabSystem.liveTab(forTab: tabID)?.webContent.reload()
    case .duplicateTab:
      withAnimation {
        dependencies.tabSystem.duplicateTab(groupModel.selectedTabModel.id)
      }
    case .pinTab:
      print(">>> implement me!")
    case .unpinTab:
      print(">>> implement me!")
    case .muteTab:
      print(">>> implement me!")
    case .unmuteTab:
      print(">>> implement me!")
    case .toggleTabMode:
      withAnimation {
        cycleTabsStyle()
      }
    case .closeTab:
      withAnimation {
        dependencies.tabSystem.remove(tab: tabID)
      }
    case .closeOtherTabs:
      withAnimation {
        dependencies.tabSystem.removeTabs(excludingTab: tabID)
      }
    case .closeTabsAfter:
      withAnimation {
        dependencies.tabSystem.removeTabs(afterTab: tabID)
      }
    case .closeWindow:
      dependencies.tabSystem.remove(group: groupModel.id)
    case .goBack:
      dependencies.tabSystem.liveTab(forTab: tabID)?.webContent.goBack()
    case .goForward:
      dependencies.tabSystem.liveTab(forTab: tabID)?.webContent.goForward()
    case .selectNextTab:
      withAnimation(animationForSelectTab) {
        dependencies.tabSystem.selectNextTab(forGroup: groupModel.value)
      }
    case .selectPreviousTab:
      withAnimation(animationForSelectTab) {
        dependencies.tabSystem.selectPreviousTab(forGroup: groupModel.value)
      }
    case .selectTabAt0:
      selectTabAt(index: 0)
    case .selectTabAt1:
      selectTabAt(index: 1)
    case .selectTabAt2:
      selectTabAt(index: 2)
    case .selectTabAt3:
      selectTabAt(index: 3)
    case .selectTabAt4:
      selectTabAt(index: 4)
    case .selectTabAt5:
      selectTabAt(index: 5)
    case .selectTabAt6:
      selectTabAt(index: 6)
    case .selectTabAt7:
      selectTabAt(index: 7)
    case .selectTabAt8:
      selectTabAt(index: 8)
    case .selectTabAt9:
      selectTabAt(index: 9)
    }
    return nil
  }

  private func handleAddressBarAction(_ action: AddressBarView.Action) -> BrowserWindowView.Action? {
    switch action {
    case .showEditorInOverlay:
      print(">>> showEditorInOverlay")
      let overlayViewModel = ensureOverlayViewModel()
      overlayViewModel.addressBarViewModel = contentViewModel.contentToolbarViewModel.addressBarViewModel
      contentViewModel.contentBodyViewModel.webContentViewModel.inputDisabled = true
    }
    return nil
  }

  private func handleDownloadsAction(_ action: RecentDownloadsView.Action) {
    switch action {
    case .openFile(let downloadID):
      #if os(macOS)
      if let fileLocation = dependencies.downloadsManager.model.downloads[downloadID]?.fileLocation {
        NSWorkspace.shared.open(fileLocation)
      }
      #endif
    case .openFolder(let downloadID):
      #if os(macOS)
      if let fileLocation = dependencies.downloadsManager.model.downloads[downloadID]?.fileLocation {
        NSWorkspace.shared.activateFileViewerSelecting([fileLocation])
      }
      #endif
    }
  }

  private func handleAddressBarEditorAction(_ action: AddressBarEditorView.Action) -> BrowserWindowView.Action? {
    let tabModel = groupModel.selectedTabModel

    func dismiss() {
      overlayViewModel = nil
      contentViewModel.contentBodyViewModel.webContentViewModel.inputDisabled = false
      contentViewModel.contentToolbarViewModel.addressBarViewModel.handleURLChanged(tabModel.url)
    }

    switch action {
    case .submit(let text):
      print(">>> submit: \(text)")

      guard let url = URL.fromUserInput(text) else {
        // Reset back to the current tab model.
        contentViewModel.contentToolbarViewModel.handleURLChanged(tabModel.url)
        return nil
      }
   
      // TODO: Navigate the tab!
      dependencies.tabSystem.load(.init(url: url), inTab: tabModel.id)
      dismiss()

    case .dismissed:
      // TODO: In the future there may be other reasons why the overlay should be open.
      print(">>> address bar editor dismissed...")
      dismiss()
    }
    return nil
  }

  private func ensureOverlayViewModel() -> BrowserWindowOverlayViewModel {
    if let overlayViewModel {
      return overlayViewModel
    }
    let overlayViewModel = BrowserWindowOverlayViewModel(dependencies: dependencies, groupModel: groupModel)
    self.overlayViewModel = overlayViewModel
    return overlayViewModel
  }

  private func makeNewTab() {
    withAnimation {
      dependencies.tabSystem.load(newTabNavigation, inGroup: groupModel.id)
    }
    focusAddressBarEditor(blank: true)
  }

  private func makeNewTab(after tabID: TabID) {
    withAnimation {
      dependencies.tabSystem.load(newTabNavigation, afterTab: tabID)
    }
    focusAddressBarEditor(blank: true)
  }

  private func focusAddressBarEditor(blank: Bool) {
    contentViewModel.contentToolbarViewModel.addressBarViewModel.focusEditor(blank: blank, selectAll: true)
  }

  /// Input is 1-based with 0 meaning select the last tab.
  private func selectTabAt(index: Int) {
    let index =
      if groupModel.tabIDs.count > 0 {
        if index == 0 { // Identifies the last tab.
          groupModel.tabIDs.count - 1
        } else {
          clamp(index - 1, 0, groupModel.tabIDs.count - 1)
        }
      } else {
        0
      }
    withAnimation(animationForSelectTab) {
      dependencies.tabSystem.select(tabAtIndex: index, inGroup: groupModel.value)
    }
  }

  private func updateTopTabsInsets() {
    topTabsViewModel.insets = .init(
      leading: titleBarInsets.leading,
      trailing: titleBarInsets.trailing + (groupSelectorIsVisible ? groupSelectorWidth : 0),
      top: titleBarInsets.top,
      bottom: titleBarInsets.bottom,
    )
  }

  private func updateContentToolbarEdgeInsets() {
    contentViewModel.contentToolbarViewModel.insets =
      if tabsVisibility == .hidden {
        .init(
          leading: titleBarInsets.leading + (tabsStyle == .sideTabs ? titleBarHeight - ContentToolbarView.Metrics.buttonPadding : 0),
          trailing: titleBarInsets.trailing,
          top: 0,
          bottom: 0,
        )
      } else if tabsStyle == .sideTabs {
        .init(
          leading:
            (sideTabsWidth < titleBarInsets.leading ? titleBarInsets.leading - sideTabsWidth : 0)
              + (showSideTabsToggleButtonOnToolbar ? titleBarHeight - ContentToolbarView.Metrics.buttonPadding : 0),
          trailing: titleBarInsets.trailing,
          top: 0,
          bottom: 0,
        )
      } else {
        .zero
      }
  }
}