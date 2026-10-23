import Foundation
import Observation
import SparrowCommands
import SparrowProfileModel
import SparrowProfiles
import SparrowSpaces
import SparrowSpacesUI
import SparrowStorage
import SparrowTabs
import SparrowToolbelt
import SparrowUI
import SparrowWindow
import SparrowWindowModel

#if os(macOS)
import AppKit
#elseif os(Windows)
import WinSDK
#endif

@MainActor
public protocol WindowManager {
  func initialize()

  func handleCommand(_ commandID: SparrowCommand.ID)
}

public protocol WindowManagerProviding {
  @MainActor
  var windowManager: WindowManager { get }
}

public typealias WindowManagerDependencies
  = ProfileSystemProviding
  & WindowSystemModelProviding

extension Factory where Interface == WindowManager {
  public static func makeDefaultInstance(dependencies: WindowManagerDependencies) -> WindowManager {
    DefaultWindowManager(dependencies: dependencies)
  }
}

final class DefaultWindowManager: WindowManager {
  init(dependencies: WindowManagerDependencies) {
    self.dependencies = dependencies
  }

  func initialize() {
    if restoreBrowserWindows().isEmpty {
      createBrowserWindow(inProfile: .default)
    }

    Task<Void, Never> {
      for await windowModels in Observations({ [windowSystemModel = dependencies.windowSystemModel] in
        windowSystemModel.browserWindows.values
      }) {
        for windowModel in windowModels where BrowserWindow.find(byID: windowModel.id) == nil {
          createBrowserWindow(forModel: windowModel)
        }
      }
    }
  }

  func createBrowserWindow(forGroup groupID: TabGroupID = .newSpace(), inProfile profileID: ProfileID) {
    dependencies.windowSystemModel.createBrowserWindow(forGroup: groupID, inProfile: profileID)
  }

  func restoreBrowserWindows() -> [BrowserWindow] {
    let windowSystemModel = dependencies.windowSystemModel

    var windows = [WindowID: BrowserWindow]()

    for window in windowSystemModel.browserWindows.values {
      windows[window.id] = createBrowserWindow(forModel: window)
    }

    BrowserWindow.finishRestorationOf(windows: windows, windowSystemModel: dependencies.windowSystemModel)

    return Array(windows.values)
  }

  func handleCommand(_ commandID: SparrowCommand.ID) {
    if commandID == .undoClose {
      handleUndoClose()
    } else if let window = lastActiveBrowserWindow {
      window.viewModel.handleCommand(commandID).flatMap { handleBrowserWindowAction(.view($0), for: window) }
    } else {
      // TODO: Figure out how to handle commands when no window is open.
      print(">>> unhandled command: \(commandID)")
    }
  }

  private weak var lastActiveBrowserWindow: BrowserWindow? {
    didSet {
      if let lastActiveBrowserWindow {
        lastActiveProfileID = lastActiveBrowserWindow.profileID
      }
    }
  }

  private var lastActiveProfileID: ProfileID?

  @discardableResult
  private func createBrowserWindow(forModel windowModel: BrowserWindowModel) -> BrowserWindow {
    let groupID = windowModel.groupID

    let container = browserWindowContainer(for: windowModel)
    let tabSystem = container.tabSystem

    let groupModel = tabSystem.model(forGroup: groupID)

    ensureAtLeastOneTab(for: groupModel, in: tabSystem)

    let viewModel = BrowserWindowViewModel(dependencies: container, groupModel: .init(groupModel))

    let window = BrowserWindow(
      dependencies: container,
      windowModel: windowModel,
      viewModel: viewModel,
    ) { [weak self] in
      let browserWindow = BrowserWindow.find(byID: windowModel.id)
      guard let self, let browserWindow else { return }
      handleBrowserWindowAction($0, for: browserWindow)
    }

    #if os(macOS)
    window.center()
    window.makeKeyAndOrderFront(nil)
    #elseif os(Windows)
    window.initialize() { [weak window] in
      try! window?.activate()
    }
    #endif

    lastActiveBrowserWindow = window
    setUpObservers(for: window)

    return window
  }

  private func handleBrowserWindowAction(_ action: BrowserWindow.Action, for window: BrowserWindow) {
    switch action {
    case .view(.quit):
      #if os(macOS)
      NSApp.terminate(nil)
      #elseif os(Windows)
      print(">>> TODO: implement `quit` action!")
      #endif
    case .view(.newWindow):
      createBrowserWindow(inProfile: window.profileID)
    case .view(.newIncognitoWindow):
      createBrowserWindow(inProfile: window.profileID.incognitoVariant)
    case .view(.close):
      #if os(macOS)
      window.close()
      #elseif os(Windows)
      try! window.close()
      #endif
    case .view(.applyColorScheme(let colorScheme)):
      window.applyColorScheme(colorScheme)
    case .view(.spaceSelector(let spaceSelectorAction)):
      handleSpaceSelectorAction(spaceSelectorAction, for: window)
    case .closed:
      handleWindowClosed(for: window)
    }
  }

  private func handleWindowClosed(for window: BrowserWindow) {
    let windowModel = window.windowModel
    for space in windowModel.scopedSpaces {
      window.viewModel.dependencies.tabSystem.remove(group: space)
    }
    dependencies.windowSystemModel.windows.removeValue(forKey: window.windowModel.id)
  }

  private func handleSpaceSelectorAction(_ action: SpaceSelectorView.Action, for window: BrowserWindow) {
    switch action {
    case .activate(let groupID):
      guard window.viewModel.groupModel.id != groupID else { return }

      if let existingWindow = BrowserWindow.find(byGroupID: groupID) {
        #if os(macOS)
        existingWindow.makeKeyAndOrderFront(nil)
        #elseif os(Windows)
        // TODO: This will un-maximize a window. Change to not do that.
        // try! existingWindow.activate()
        let hwnd = existingWindow.getHWND()!
        ShowWindow(hwnd, SW_RESTORE)
        SetForegroundWindow(hwnd)
        #endif
      } else {
        activateGroup(groupID, inWindow: window)
      }
    
    case .createScratchSpace:
      let groupID = TabGroupID.newSpace()
      window.windowModel.scopedSpaces.append(groupID)
      activateGroup(groupID, inWindow: window)

    case .createSavedSpace(let row, let col):
      let groupID = TabGroupID.newSpace()
      window.viewModel.dependencies.spaceGridModel[row: row, col: col] = groupID
      activateGroup(groupID, inWindow: window)
    }
  }

  private func handleUndoClose() {
    let profileID = lastActiveProfileID ?? .default

    guard let tabUndoManager = dependencies.profileSystem.container(for: profileID).tabUndoManager else { return }

    let entry = withAnimation {
      tabUndoManager.undo()
    }

    guard case .group(let groupModel, _) = entry else { return }
    createBrowserWindow(forGroup: groupModel.id, inProfile: profileID)
  }

  private func activateGroup(_ groupID: TabGroupID, inWindow window: BrowserWindow) {
    let tabSystem = window.viewModel.dependencies.tabSystem
    let groupModel = tabSystem.model(forGroup: groupID)

    let previousGroupID = window.windowModel.groupID
    guard previousGroupID != groupID else { return }

    ensureAtLeastOneTab(for: groupModel, in: tabSystem)

    window.windowModel.groupID = groupID
    window.viewModel.groupModel.value = groupModel

    tabSystem.unloadLiveTabs(forGroup: previousGroupID)
  }

  private func ensureAtLeastOneTab(for groupModel: TabGroupModel, in tabSystem: TabSystem) {
    if groupModel.tabIDs.isEmpty {
      // TODO: Add proper initialization for tab groups. For now just add a dummy initial tab.
      tabSystem.load(.init(url: URL(string: "https://news.ycombinator.com/")!), inGroup: groupModel.id)
    }
  }

  private func setUpObservers(for window: BrowserWindow) {
    #if os(macOS)
    NotificationCenter.default.addObserver(
      forName: NSWindow.didBecomeKeyNotification,
      object: window,
      queue: .main
    ) { [weak self, weak window] _ in
      MainActor.assumeIsolated {
        self?.lastActiveBrowserWindow = window
      }
    }
    #endif
  }

  private func browserWindowContainer(for browserWindowModel: BrowserWindowModel) -> BrowserWindowContainer {
    let profileID = browserWindowModel.profileID
    let container = dependencies.profileSystem.container(for: profileID)

    return .init(browserWindowModel: browserWindowModel, profileContainer: container)
  }

  private let dependencies: WindowManagerDependencies
}

extension BrowserWindow {
  var profileID: ProfileID {
    viewModel.dependencies.profileID
  }
}
