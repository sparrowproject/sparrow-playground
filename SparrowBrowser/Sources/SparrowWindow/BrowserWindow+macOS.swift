#if os(macOS)
import AppKit
import SparrowCommands
import SparrowStorage
import SparrowTabs
import SparrowToolbelt
import SparrowUI
import SparrowWindowModel
import Tagged
import WebKit

public typealias BrowserWindowDependencies
  = Any

public final class BrowserWindow: NSWindow, Sendable {
  public enum Action {
    case view(BrowserWindowView.Action)
    case closed
  }

  public init(
    dependencies: BrowserWindowDependencies,
    windowModel: BrowserWindowModel,
    viewModel: BrowserWindowViewModel,
    action: @escaping (Action) -> Void,
  ) {
    self.windowModel = windowModel
    self.viewModel = viewModel
    self.action = action

    let initialSize = CGSize(width: 1024, height: 680)
    super.init(
      contentRect: .init(origin: .zero, size: initialSize),
      styleMask: [.titled, .closable, .fullSizeContentView, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    title = "Sparrow Browser"
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    toolbarStyle = .unifiedCompact
    isOpaque = false
    backgroundColor = .clear
    isReleasedWhenClosed = false
    isRestorable = true
    restorationClass = BrowserWindowRestoration.self

    identifier = NSUserInterfaceItemIdentifier(rawValue: windowModel.id.uuidString)

    // This is required to get the right titlebar sizing and desired window corners.
    // It is not used otherwise.
    let toolbar = NSToolbar(identifier: "main-toolbar")
    toolbar.displayMode = .iconOnly
    self.toolbar = toolbar

    contentView = backgroundView

    backgroundView.addSubview(windowInteractionView)
    backgroundView.addSubview(browserWindowView)

    windowInteractionView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      windowInteractionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
      windowInteractionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
      windowInteractionView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
      windowInteractionView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
    ])

    browserWindowView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      browserWindowView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
      browserWindowView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
      browserWindowView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
      browserWindowView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
    ])

    windowInteractionView.onPointerTracking = { [weak browserWindowView] in
      browserWindowView?.suppressPointerUpdates = $0
    }

    // Just grab this once.
    updateTitleBarHeight()

    setUpObservers()
  }

  public let windowModel: BrowserWindowModel
  public let viewModel: BrowserWindowViewModel

  public static func find(byID windowID: WindowID) -> BrowserWindow? {
    for window in NSApp.windows {
      if
        let browserWindow = window as? BrowserWindow,
        browserWindow.windowModel.id == windowID,
        !browserWindow.isClosed
      {
        return browserWindow
      }
    }
    return nil
  }

  public static func find(byGroupID groupID: TabGroupID) -> BrowserWindow? {
    for window in NSApp.windows {
      if
        let browserWindow = window as? BrowserWindow,
        browserWindow.viewModel.groupModel.id == groupID,
        !browserWindow.isClosed
      {
        return browserWindow
      }
    }
    return nil
  }

  public override func layoutIfNeeded() {
    super.layoutIfNeeded()

    updateTitleBarInsets()
  }

  public override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
    // TODO: Come up with a more robust solution to preventing unwanted focus changes
    // when the address bar should have focus.
    if
      viewModel.contentViewModel.contentToolbarViewModel.addressBarViewModel.editorHasFocus,
      (responder as? WKWebView) != nil
    {
      return false
    }
    return super.makeFirstResponder(responder)
  }

  public override func performKeyEquivalent(with event: NSEvent) -> Bool {
    print(">>> performKeyEquivalent, characters: \(event.charactersIgnoringModifiers)")

    defer {
      // Flush any updates immediately in response to a keybinding press.
      // This is especially needed in case keybindings are being spammed.
      browserWindowView.context.scheduler.flushUpdates()
    }

    // Ensure that any browser-reserved keybindings are handled directly
    // bypassing the first responder (which may be the WebView).
    if
      let mainMenu = NSApp.mainMenu,
      let menuItem = mainMenu.item(matchingKeyEquivalent: event)
    {
      let isReservedCommandID = SparrowCommand.ID(rawValue: menuItem.tag).flatMap({
        SparrowCommand.browserReservedIDs.contains($0)
      }) ?? false
      if isReservedCommandID {
        return mainMenu.performKeyEquivalent(with: event)
      }
    }

    return super.performKeyEquivalent(with: event)
  }

  public static func finishRestorationOf(
    windows: [WindowID: BrowserWindow],
    windowSystemModel _: WindowSystemModel,
  ) {
    let restorableWindows = Self.restorableWindows
    Self.restorableWindows = []
    for restorableWindow in restorableWindows {
      if let window = windows[restorableWindow.windowID] {
        print(">>> restoring window w/ id: \(restorableWindow.windowID)")
        restorableWindow.completionHandler(window, nil)
      } else {
        print(">>> no group data found for restorable window w/ id: \(restorableWindow.windowID)")
        restorableWindow.completionHandler(nil, nil)
      }
    }
  }

  public func applyColorScheme(_ colorScheme: ColorScheme?) {
    switch colorScheme {
    case .dark:
      appearance = NSAppearance(named: .darkAqua)
    case .light:
      appearance = NSAppearance(named: .aqua)
    case .none:
      appearance = nil
    }
  }

  struct RestorableWindow {
    let windowID: WindowID
    let completionHandler: (NSWindow?, Error?) -> Void
  }

  static var restorableWindows = [RestorableWindow]()

  private let action: (Action) -> Void
  private var isFullScreen = false
  private var isClosed = false

  private lazy var windowInteractionView = WindowInteractionView()

  private lazy var browserWindowView = NSHostingView(
    content: BrowserWindowView(viewModel: viewModel) { [action] in
      action(.view($0))
    }
  )

  private lazy var backgroundView: NSView = {
    // Create the visual effect view.
    let effectView = NSVisualEffectView()
    effectView.autoresizingMask = [.width, .height]

    // Configure the material.
    effectView.material = .menu
    effectView.blendingMode = .behindWindow
    effectView.state = .active

    return effectView
  }()

  private var toolbarFullScreenWindow: NSWindow? {
    for window in NSApp.windows {
      if NSStringFromClass(type(of: window)) == "NSToolbarFullScreenWindow" {
        return window
      }
    }
    return nil
  }

  private func setUpObservers() {
    NotificationCenter.default.addObserver(
      forName: NSWindow.willEnterFullScreenNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.willEnterFullScreen()
      }
    }

    NotificationCenter.default.addObserver(
      forName: NSWindow.didEnterFullScreenNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.didEnterFullScreen()
      }
    }

    NotificationCenter.default.addObserver(
      forName: NSWindow.willExitFullScreenNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.willExitFullScreen()
      }
    }

    NotificationCenter.default.addObserver(
      forName: NSWindow.didExitFullScreenNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.didExitFullScreen()
      }
    }

    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.willClose()
      }
    }
  }

  private func updateTitleBarHeight() {
    viewModel.titleBarHeight = frame.height - contentLayoutRect.height
  }

  private func updateTitleBarInsets() {
    if isFullScreen {
      viewModel.titleBarInsets = .zero
      return
    }

    guard
      let close = standardWindowButton(.closeButton),
      let mini = standardWindowButton(.miniaturizeButton),
      let zoom = standardWindowButton(.zoomButton)
    else {
      return
    }

    let rect = close.frame
      .union(mini.frame)
      .union(zoom.frame)

    let paddingX = rect.minX
    
    let insets = EdgeInsets(
      leading: rect.maxX + paddingX,
      trailing: 0,
      top: 0,
      bottom: 0,
    )
    viewModel.titleBarInsets = insets
  }

  private func willEnterFullScreen() {
    toolbar?.isVisible = false
    isFullScreen = true
  }

  private func didEnterFullScreen() {
    toolbarFullScreenWindow?.hasShadow = true
  }

  private func willExitFullScreen() {
    isFullScreen = false
  }

  private func didExitFullScreen() {
    // TODO: This seems to be the only way to get the traffic lights to be positioned
    // properly after exiting fullscreen. Perhaps there is a better solution we can
    // use from `willExitFullScreenNotification`.
    toolbar?.isVisible = true

    toolbar?.validateVisibleItems()
    displayIfNeeded()
  }

  private func willClose() {
    isClosed = true

    action(.closed)

    // Try to discard resources even if the window itself leaks...
    browserWindowView.tearDown()
  }
}

private final class WindowInteractionView: NSView {
  var onPointerTracking: ((Bool) -> Void)?

  @MainActor
  deinit {
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
    }
  }

  override func mouseDown(with event: NSEvent) {
    guard event.type == .leftMouseDown else {
      super.mouseDown(with: event)
      return
    }

    // Use an event monitor here instead of `mouseUp` since that could be missed
    // if the target subview gets removed as a side-effect of `mouseDown` handling.
    // It is critical that we know when the mouse button is released.
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
    }
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
      self?.handleLeftMouseUp()
      return event
    }

    onPointerTracking?(true)
    if event.clickCount == 2 {
      window?.performZoom(nil)
    } else {
      window?.performDrag(with: event)
    }
  }

  private var eventMonitor: Any?

  private func handleLeftMouseUp() {
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }
    onPointerTracking?(false)
  }
}

private final class BrowserWindowRestoration: NSObject, NSWindowRestoration {
  static func restoreWindow(
    withIdentifier identifier: NSUserInterfaceItemIdentifier,
    state: NSCoder,
    completionHandler: @escaping (NSWindow?, Error?) -> Void
  ) {
    print(">>> restoreWindow, identifier: \(identifier)")

    guard let windowID = UUID(uuidString: identifier.rawValue).flatMap({ WindowID($0) }) else {
      completionHandler(nil, nil)
      return
    }

    BrowserWindow.restorableWindows.append(
      .init(windowID: windowID, completionHandler: completionHandler),
    )
  }
}

extension NSMenu {
  fileprivate func item(matchingKeyEquivalent event: NSEvent) -> NSMenuItem? {
    let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

    for item in items {
      if let submenu = item.submenu,
        let match = submenu.item(matchingKeyEquivalent: event) {
        return match
      }

      guard !item.keyEquivalent.isEmpty else {
        continue
      }

      if item.keyEquivalent == event.charactersIgnoringModifiers?.lowercased(),
        item.keyEquivalentModifierMask == modifiers {
        return item
      }
    }

    return nil
  }
}

#endif
