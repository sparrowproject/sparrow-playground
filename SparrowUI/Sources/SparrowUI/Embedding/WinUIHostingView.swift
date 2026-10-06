#if os(Windows)
import Foundation
import Observation
import OrderedCollections
import SparrowUICore
import WinAppSDK
import WindowsFoundation
import WinSDK
import WinUI

@MainActor
public final class WinUIHostingView<Content: View>: UserControl, Sendable {
  public init(content: Content, context: CoreViewContext = .init()) {
    self.context = context

    rootView = .init(context: context)
    rootView.configureAsRootView()

    context.rootView = rootView

    let contentView = ViewBuilder(content: content).buildView(context: context)
    self.contentView = contentView

    super.init()

    print(">>> WinUIHostingView created @ \(ObjectIdentifier(self))")

    context.delegate = self

    rootView.subviews = { [contentView] }

    rootView.width = { [layoutState] in layoutState.width }
    rootView.height = { [layoutState] in layoutState.height }

    isHitTestVisible = true

    self.content = grid

    loaded.addHandler { [weak self] _, _ in
      self?.onLoaded()
    }

    sizeChanged.addHandler { [weak self] _, args in
      self?.onSizeChanged(args!)
    }
  }

  deinit {
    print(">>> WinUIHostingView destroyed @ \(ObjectIdentifier(self))")
  }

  public override func onPointerPressed(_ event: PointerRoutedEventArgs!) throws {
    let pointer = event.pointer
    let details = event.details(relativeTo: self)

    event.handled = MainActor.assumeIsolated {
      let coreEvent = CorePointerEvent(details: details)
      eventRouter.handlePointerDown(event: coreEvent)
      return coreEvent.handled
    }

    if try! capturePointer(pointer) {
      capturedPointer = pointer
      capturedPointerLastPosition = details.location
    } else {
      MainActor.assumeIsolated {
        eventRouter.handlePointerCaptureLost()
      }
    }
  }

  public override func onPointerReleased(_ event: PointerRoutedEventArgs!) throws {
    let details = event.details(relativeTo: self)

    event.handled = MainActor.assumeIsolated {
      let coreEvent = CorePointerEvent(details: details)
      eventRouter.handlePointerUp(event: coreEvent)
      endCapture()
      return coreEvent.handled
    }
  }

  public override func onPointerEntered(_ event: PointerRoutedEventArgs!) throws {
    let details = event.details(relativeTo: self)

    MainActor.assumeIsolated {
      eventRouter.handlePointerEntered(event: .init(details: details))
    }
  }

  public override func onPointerMoved(_ event: PointerRoutedEventArgs!) throws {
    let details = event.details(relativeTo: self)

    event.handled = MainActor.assumeIsolated {
      if let capturedPointerLastPosition {
        let deltaX = details.location.x - capturedPointerLastPosition.x
        let deltaY = details.location.y - capturedPointerLastPosition.y
        self.capturedPointerLastPosition = details.location

        let coreEvent = CorePointerDragEvent(
          details: details,
          deltaX: deltaX,
          deltaY: deltaY,
        )
        eventRouter.handlePointerDragged(event: coreEvent)
        return coreEvent.handled
      }

      let coreEvent = CorePointerEvent(details: details)
      eventRouter.handlePointerMoved(event: coreEvent)
      return coreEvent.handled
    }
  }

  public override func onPointerExited(_ event: PointerRoutedEventArgs!) throws {
    let details = event.details(relativeTo: self)

    MainActor.assumeIsolated {
      eventRouter.handlePointerExited(event: .init(details: details))
    }
  }

  public override func onPointerCaptureLost(_ event: PointerRoutedEventArgs!) throws {
    MainActor.assumeIsolated {
      capturedPointerLastPosition = nil
      capturedPointer = nil

      eventRouter.handlePointerCaptureLost()
    }
  }

  public override func onPointerCanceled(_ event: PointerRoutedEventArgs!) throws {
    MainActor.assumeIsolated {
      endCapture()
    }
  }

  public override func onPointerWheelChanged(_ event: PointerRoutedEventArgs!) throws {
    let details = event.details(relativeTo: self)

    let pointerPoint = try! event.getCurrentPoint(self)!
    let properties = pointerPoint.properties!

    let mouseWheelDelta = properties.mouseWheelDelta
    let deltaX = properties.isHorizontalMouseWheel ? mouseWheelDelta : 0
    let deltaY = properties.isHorizontalMouseWheel ? 0 : mouseWheelDelta
 
    event.handled = MainActor.assumeIsolated {
      let coreEvent = CorePointerWheelEvent(
        details: details,
        deltaX: CGFloat(deltaX),
        deltaY: CGFloat(deltaY),
        hasPreciseScrollDeltas: false,
      )

      eventRouter.handlePointerWheel(event: coreEvent)

      return coreEvent.handled
    }
  }

  public override func onKeyDown(_ event: KeyRoutedEventArgs!) throws {
    let virtualKey = event.key
    event.handled = MainActor.assumeIsolated {
      let coreEvent = CoreKeyEvent(key: .init(virtualKey: virtualKey), modifierFlags: .current)
      eventRouter.handleKeyDown(event: coreEvent)
      return coreEvent.handled
    }
  }

  public override func onKeyUp(_ event: KeyRoutedEventArgs!) throws {
    let virtualKey = event.key
    event.handled = MainActor.assumeIsolated {
      let coreEvent = CoreKeyEvent(key: .init(virtualKey: virtualKey), modifierFlags: .current)
      eventRouter.handleKeyUp(event: coreEvent)
      return coreEvent.handled
    }
  }

  public func tearDown() {
    rootView.subviews = { [] }
    rootView.subviewMap.removeAll()
    canvas.children.clear()
    content = nil
  }

  @MainActor @Observable
  final class LayoutState {
    var width = CGFloat.zero
    var height = CGFloat.zero
  }

  var eventRouter: EventRouter {
    routerOverrides.last ?? defaultRouter
  }

  private let context: CoreViewContext
  private var rootView: CoreView
  private let contentView: CoreView
  private nonisolated(unsafe) var capturedPointer: Pointer?
  private nonisolated(unsafe) var capturedPointerLastPosition: CGPoint?
  private var layoutState = LayoutState()
  private var routerOverrides = [EventRouter]()

  private(set) lazy var defaultRouter: EventRouter = DefaultEventRouter(
    rootView: rootView,
    onSetCursor: { [weak self] in
      self?.updateCursor($0)
    }
  )

  private lazy var grid: Grid = {
    let grid = Grid()
    grid.background = SolidColorBrush(CoreColor.clear.value)
    grid.children.append(baseLayer)
    grid.children.append(canvas)
    return grid
  }()
  private lazy var baseLayer = UserControl()
  private lazy var canvas = Canvas()

  private func onLoaded() {
    try! ElementCompositionPreview.setElementChildVisual(baseLayer, rootView.visual)

    context.backingScaleFactor = xamlRoot!.rasterizationScale
    xamlRoot!.changed.addHandler { [weak self] _, _ in
      guard let self, let scale = xamlRoot?.rasterizationScale else { return }
      if context.backingScaleFactor != scale {
        context.backingScaleFactor = scale
      }
    }

    context.colorScheme = ColorScheme.from(actualTheme)    
    actualThemeChanged.addHandler { [weak self] _, _ in
      self?.onActualThemeChanged()
    }
  }

  private func onSizeChanged(_ args: SizeChangedEventArgs) {
    layoutState.width = CGFloat(args.newSize.width)
    layoutState.height = CGFloat(args.newSize.height)

    context.scheduler.flushUpdates()
  }

  private func onActualThemeChanged() {
    let colorScheme = ColorScheme.from(actualTheme)
    if context.colorScheme != colorScheme {
      context.colorScheme = colorScheme
    }
  }

  private func endCapture() {
    if let capturedPointer {
      try! releasePointerCapture(capturedPointer)
      self.capturedPointerLastPosition = nil
      self.capturedPointer = nil
      eventRouter.handlePointerCaptureLost()
    }
  }

  private func updateCursor(_ cursor: Cursor?) {
    if let cursor {
      protectedCursor = try! InputSystemCursor.create(InputSystemCursorShape.from(cursor))
    } else {
      protectedCursor = nil
    }
  }
}

extension WinUIHostingView: CoreViewContext.Delegate {
  public var containingUIElement: UIElement {
    self
  }

  public var containingUIElementChildren: UIElementCollection {
    canvas.children
  }

  public func didFlushUpdates() {
    guard let details = PointerRoutedEventArgs.currentDetails(relativeTo: self) else { return }
    eventRouter.updateHoveredViews(event: .init(details: details))
  }

  public func addEmbeddedUIElement(_ element: UIElement) {
    print(">>> addEmbeddedUIElement")
    canvas.children.append(element)
  }

  public func removeEmbeddedUIElement(_ element: UIElement) {
    if let index = canvas.children.index(of: element) {
      canvas.children.removeAt(UInt32(index))
    }
  }

  public func updateEmbeddedViews(_ elements: [UIElement]) {
    canvas.children.replaceAll(elements)
  }
}


extension WinUIHostingView: HostingView {
  func pushEventRouter(_ router: EventRouter) {
    routerOverrides.append(router)
  }

  func popEventRouter(_ router: EventRouter) {
    guard routerOverrides.last === router else {
      assertionFailure("Given EventRouter cannot be popped!")
      return
    }
    routerOverrides.removeLast()
  }
}

extension PointerRoutedEventArgs {
  fileprivate func details(relativeTo element: UIElement) -> PointerEventDetails {
    let pointerPoint = try! getCurrentPoint(element)!
    return .init(
      location: .init(pointerPoint.position),
      buttons: pointerPoint.buttons,
      modifiers: .init(keyModifiers),
    )
  }

  fileprivate static func currentDetails(relativeTo element: UIElement) -> PointerEventDetails? {
    // The element might not be loaded yet.
    guard
      let root = element.xamlRoot,
      let hwnd = element.appWindow?.getHWND()
    else {
      return nil
    }

    var cursorPos = POINT()
    GetCursorPos(&cursorPos)
    ScreenToClient(hwnd, &cursorPos)

    let scale = root.rasterizationScale
    let pointInRoot = Point(
      x: Float(cursorPos.x) / Float(scale),
      y: Float(cursorPos.y) / Float(scale),
    )

    let toRoot = try! element.transformToVisual(nil)!
    let point = try! toRoot.inverse.transformPoint(pointInRoot)

    return .init(
      location: .init(point),
      buttons: .current,
      modifiers: .current,
    )
  }
}

extension PointerPoint {
  fileprivate var buttons: PointerButtons {
    let props = properties!
    var result = PointerButtons()
    if props.isLeftButtonPressed {
      result.insert(.left)
    }
    if props.isRightButtonPressed {
      result.insert(.right)
    }
    if props.isMiddleButtonPressed {
      result.insert(.middle)
    }
    return result
  }
}

extension Keystroke.ModifierFlags {
  fileprivate static var current: Self {
    var result = Self()

    if try! InputKeyboardSource.getKeyStateForCurrentThread(.shift) == .down {
      result.insert(.shift)
    }
    if try! InputKeyboardSource.getKeyStateForCurrentThread(.control) == .down {
      result.insert(.control)
    }
    if try! InputKeyboardSource.getKeyStateForCurrentThread(.menu) == .down {
      result.insert(.menu)
    }
    if try! (
      InputKeyboardSource.getKeyStateForCurrentThread(.leftWindows) == .down ||
      InputKeyboardSource.getKeyStateForCurrentThread(.rightWindows) == .down
    ) {
      result.insert(.windows)
    }

    return result
  }
}

extension PointerButtons {
  fileprivate static var current: Self {
    var result = Self(rawValue: 0)
    if (Int(GetAsyncKeyState(VK_LBUTTON)) & 0x8000) != 0 {
      result.insert(.left)
    }
    if (Int(GetAsyncKeyState(VK_RBUTTON)) & 0x8000) != 0 {
      result.insert(.right)
    }
    if (Int(GetAsyncKeyState(VK_MBUTTON)) & 0x8000) != 0 {
      result.insert(.middle)
    }
    return result
  }
}

#endif
