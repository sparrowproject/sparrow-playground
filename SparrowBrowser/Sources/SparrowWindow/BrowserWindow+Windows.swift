#if os(Windows)
import Foundation
import OrderedCollections
import SparrowCommands
import SparrowTabs
import SparrowTabsUI
import SparrowUI
import SparrowWindowModel
import Tagged
import UWP
import WinAppSDK
import WinSDK
import WinUI

public typealias BrowserWindowDependencies
  = WindowSystemModelProviding

@MainActor
public final class BrowserWindow: Window {
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
    self.dependencies = dependencies
    self.windowModel = windowModel
    self.viewModel = viewModel
    self.action = action
    super.init()

    print(">>> BrowserWindow created @ \(ObjectIdentifier(self))")

    Self.all[windowModel.id] = self // Keeps the window alive until closed.

    closed.addHandler { [weak self] _, _ in
      self?.handleClosed()
    }
  }
  
  deinit {
    print(">>> BrowserWindow destroyed @ \(ObjectIdentifier(self))")
  }

  /// TODO: This can now become cross-platform since we have `WindowID`.
  public static var all = [WindowID: BrowserWindow]()

  public static func find(byID windowID: WindowID) -> BrowserWindow? {
    all[windowID]
  }

  public static func find(byGroupID groupID: TabGroupID) -> BrowserWindow? {
    for window in all.values {
      if window.viewModel.groupModel.id == groupID {
        return window
      }
    }
    return nil
  }

  public let dependencies: BrowserWindowDependencies
  public let windowModel: BrowserWindowModel
  public let viewModel: BrowserWindowViewModel

  public func initialize(completion: @MainActor @escaping () -> Void) {
    title = "Sparrow Browser"
    extendsContentIntoTitleBar = true
    appWindow.titleBar.preferredHeightOption = .collapsed

    systemBackdrop = MicaBackdrop()
    // systemBackdrop = DesktopAcrylicBackdrop()

    content = hostingView

    viewModel.titleBarHeight = Metrics.toolbarHeight
    viewModel.titleBarInsets = .init(
      leading: TopTabsView.Metrics.padding / 2,
      trailing: 3 * Metrics.toolbarHeight + 30, // Standard window controls.
      top: 0,
      bottom: 0,
    )
    viewModel.updateNonClientPassthroughRects = { [weak self] in
      self?.nonClientPassthroughRects = $0
    }

    hostingView.loaded.addHandler { [weak self] _, _ in
      self?.onLoaded()
      completion()
    }

    hostingView.sizeChanged.addHandler { [weak self] _, _ in
      // This is required to ensure the capture region is updated properly when resizing the window.
      self?.setAllRegionRects()
    }
  }

  public func applyColorScheme(_ colorScheme: ColorScheme?) {
    switch colorScheme {
    case .dark:
      hostingView.requestedTheme = .dark
    case .light:
      hostingView.requestedTheme = .light
    case .none:
      hostingView.requestedTheme = .default
    }
  }

  private enum Metrics {
    static let toolbarHeight: CGFloat = 40
  }

  private let action: (Action) -> Void
  private var sizeWasRestored = false

  // Retain a reference to the binding wrapper so we can attach event handlers to it.
  private lazy var _appWindow: AppWindow = appWindow

  private lazy var nonClientArea = try! InputNonClientPointerSource.getForWindowId(appWindow.id)!

  private lazy var hostingView = WinUIHostingView(
    content: BrowserWindowView(viewModel: viewModel) { [action] in
      action(.view($0))
    }
  )

  private var nonClientPassthroughRects = [CGRect]() {
    didSet {
      guard nonClientPassthroughRects != oldValue else { return }
      setAllRegionRects()
    }
  }

  private func onLoaded() {
    if !sizeWasRestored {
      // Apply default sizing:
      let scale = hostingView.xamlRoot!.rasterizationScale
      try! appWindow.resize(.init(width: Int32(1024 * scale), height: Int32(680 * scale)))
    }

    startTrackingAppWindowChanges()

    setAllRegionRects()
    nonClientArea.regionsChanged.addHandler { [weak self] _, event in
      guard let self else { return }
      let regionRects = computeRegionRects()
      for kind in event!.changedRegions {
        guard let desiredRects = regionRects[kind] else { continue }
        let currentRects = try! nonClientArea.getRegionRects(kind)
        if currentRects != desiredRects {
          try! nonClientArea.setRegionRects(kind, desiredRects)
        }
      }
    }
  }

  private func startTrackingAppWindowChanges() {
    _appWindow.changed.addHandler { [weak self] _, args in
      self?.handleAppWindowChanged(args: args!)
    }
    updateWindowData()
  }

  private func computeRegionRects() -> [NonClientRegionKind: [RectInt32]] {
    guard let scale = hostingView.xamlRoot?.rasterizationScale else { return [:] }

    let clientSize = appWindow.clientSize

    let width = clientSize.width // The non-client area has the same width as the client area.
    let unit = Int32(Metrics.toolbarHeight * scale)
  
    var regions = [NonClientRegionKind: [RectInt32]]()
    regions[.caption] = [.init(x: 0, y: 0, width: width - 3 * unit, height: unit)]
    regions[.minimize] = [.init(x: width - (3 * unit), y: 0, width: unit, height: unit)]
    regions[.maximize] = [.init(x: width - (2 * unit), y: 0, width: unit, height: unit)]
    regions[.close] = [.init(x: width - unit, y: 0, width: unit, height: unit)]

    // TODO: Add passthrough rects when toolbar buttons overlap with the titlebar.
    regions[.passthrough] = nonClientPassthroughRects.map {
      .init(
        x: Int32($0.minX * scale),
        y: Int32($0.minY * scale),
        width: Int32($0.width * scale),
        height: Int32($0.height * scale),
      )
    }

    return regions
  }

  private func setAllRegionRects() {
    for (kind, rects) in computeRegionRects() {
      try! nonClientArea.setRegionRects(kind, rects)
    }
  }

  private func handleClosed() {
    action(.closed)

    // Try to discard resources even if the window itself leaks...
    hostingView.tearDown()
    content = nil

    Self.all.removeValue(forKey: windowModel.id)
  }

  private func handleAppWindowChanged(args: AppWindowChangedEventArgs) {
    if args.didPositionChange || args.didSizeChange {
      updateWindowData()
    }
    if args.didZOrderChange {
      print(">>> didZOrderChange")
      let sortedIDs = windowsInZOrder(Self.all.values).map(\.viewModel.groupModel.id.rawValue)
      // TODO:
      // dependencies.windowDataStore.model.reorder(byIDs: sortedIDs)
    }
  }

  private func updateWindowData() {
    windowModel.frame = .init(
      origin: _appWindow.position,
      size: _appWindow.size,
    )
  }
}

extension BrowserWindow {
  public static func finishRestorationOf(
    windows: [WindowID: BrowserWindow],
    windowSystemModel: WindowSystemModel,
  ) {
    for windowModel in windowSystemModel.browserWindows.values {
      if
        let frame = windowModel.frame,
        let window = windows[windowModel.id]
      {
        let constrainedFrame = constrain(
          frame,
          to: currentDisplayArea(for: frame).workArea
        )
        try! window.appWindow.moveAndResize(constrainedFrame)
        window.sizeWasRestored = true
      }
    }

    // TODO: Figure out z-order and apply saved window style.
  }
}

private func currentDisplayArea(for frame: DisplayRect) -> DisplayArea {
  try! DisplayArea.getFromRect(frame, .nearest)
}

private func constrain(_ frame: DisplayRect, to workArea: DisplayRect) -> DisplayRect {
  let width = min(frame.width, workArea.width)
  let height = min(frame.height, workArea.height)

  return .init(
    x: clamped(frame.x, min: workArea.minX, max: workArea.maxX - width),
    y: clamped(frame.y, min: workArea.minY, max: workArea.maxY - height),
    width: width,
    height: height,
  )
}

private func clamped(_ value: DisplayUnit, min minValue: DisplayUnit, max maxValue: DisplayUnit) -> DisplayUnit {
  min(max(value, minValue), maxValue)
}

private func windowsInZOrder<S: Sequence<BrowserWindow>>(_ windows: S) -> [BrowserWindow] {
  let byHWND = Dictionary(
    uniqueKeysWithValues: windows.map {
      ($0.getHWND()!, $0)
    }
  )

  var result: [BrowserWindow] = []

  // Start at the top of the global Z-order.
  var hwnd = GetTopWindow(nil)

  while hwnd != nil {
    if let window = byHWND[hwnd!] {
      result.append(window)
    }
    hwnd = GetWindow(hwnd, UINT(GW_HWNDNEXT))
  }

  return result
}

#endif
