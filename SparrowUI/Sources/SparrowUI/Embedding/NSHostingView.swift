#if os(macOS)
import AppKit
import Foundation
import OrderedCollections
import SparrowUICore
import SparrowUIFoundation

/// An `NSView` that hosts a `View` tree.
public final class NSHostingView<Content: View>: NSView {
  public init(content: Content, context: CoreViewContext = .init()) {
    self.context = context

    rootView = .init(context: context)
    rootView.configureAsRootView()

    context.rootView = rootView

    let contentView = ViewBuilder(content: content).buildView(context: context)
    self.contentView = contentView

    super.init(frame: .zero)
    // print(">>> creating NSHostingView @\(ObjectIdentifier(self))")

    wantsLayer = true

    context.delegate = self

    rootView.subviews = { [contentView] }

    rootView.width = { [layoutState] in layoutState.width }
    rootView.height = { [layoutState] in layoutState.height }

//    addSubview(debugButton)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    // print(">>> destroying NSHostingView @\(ObjectIdentifier(self))")
  }

  public let context: CoreViewContext
  public let contentView: CoreView

  public var suppressPointerUpdates = false {
    didSet {
      if !suppressPointerUpdates {
        didFlushUpdates()
      }
    }
  }

  public override var isFlipped: Bool {
    true
  }

  public override var acceptsFirstResponder: Bool {
    true
  }

  public override var mouseDownCanMoveWindow: Bool {
    false
  }

  public override var safeAreaInsets: NSEdgeInsets {
    .init(top: 0, left: 0, bottom: 0, right: 0)
  }

  public override func becomeFirstResponder() -> Bool {
    let result = super.becomeFirstResponder()
    print(">>> NSHostingView @\(ObjectIdentifier(self)) became first responder!")
    return result
  }

  public override func resignFirstResponder() -> Bool {
    let result = super.resignFirstResponder()
    print(">>> NSHostingView @\(ObjectIdentifier(self)) resigned first responder!")
    return result
  }

  public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  public override func makeBackingLayer() -> CALayer {
    rootView.layer
  }

  public override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    context.colorScheme = ColorScheme.from(effectiveAppearance)
    ColorSchemeProvider.shared.colorScheme = context.colorScheme
  }

  public override func viewWillMove(toWindow newWindow: NSWindow?) {
    if let window {
      NotificationCenter.default.removeObserver(
        self,
        name: NSWindow.didChangeBackingPropertiesNotification,
        object: window
      )
    }
    super.viewWillMove(toWindow: newWindow)
  }

  public override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()

    context.backingScaleFactor = window?.backingScaleFactor ?? 1

    if let window {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(onWindowBackingPropertiesChanged),
        name: NSWindow.didChangeBackingPropertiesNotification,
        object: window,
      )
    }
  }

  public override func layout() {
    super.layout()

    if layoutState.width != bounds.size.width {
      layoutState.width = bounds.size.width
    }
    if layoutState.height != bounds.size.height {
      layoutState.height = bounds.size.height
    }

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    context.scheduler.flushUpdates()

    CATransaction.commit()

    debugButton.frame = .init(x: 5, y: 0, width: 80, height: 32)
  }

  // TODO: Add support for event bubbling and suppression.

  public override func mouseDown(with event: NSEvent) {
    if handleAnyMouseDown(with: event) {
      super.mouseDown(with: event)
    }
  }

  public override func mouseUp(with event: NSEvent) {
    if handleAnyMouseUp(with: event) {
      super.mouseUp(with: event)
    }
  }

  public override func rightMouseDown(with event: NSEvent) {
    if handleAnyMouseDown(with: event) {
      super.rightMouseDown(with: event)
    }
  }

  public override func rightMouseUp(with event: NSEvent) {
    if handleAnyMouseUp(with: event) {
      super.rightMouseUp(with: event)
    }
  }

  public override func otherMouseDown(with event: NSEvent) {
    if handleAnyMouseDown(with: event) {
      super.otherMouseDown(with: event)
    }
  }

  public override func otherMouseUp(with event: NSEvent) {
    if handleAnyMouseUp(with: event) {
      super.otherMouseUp(with: event)
    }
  }

  public override func mouseEntered(with event: NSEvent) {
    super.mouseEntered(with: event)

    guard !suppressPointerUpdates else { return }

    eventRouter.handlePointerEntered(
      event: .init(details: event.pointerDetails(relativeTo: self)),
    )
  }

  public override func mouseExited(with event: NSEvent) {
    super.mouseExited(with: event)

    guard !suppressPointerUpdates else { return }

    eventRouter.handlePointerExited(
      event: .init(details: event.pointerDetails(relativeTo: self)),
    )
  }

  public override func mouseMoved(with event: NSEvent) {
    guard !suppressPointerUpdates else { return }

    let coreEvent = CorePointerEvent(details: event.pointerDetails(relativeTo: self))

    eventRouter.handlePointerMoved(event: coreEvent)

    if shouldPropagateEvent(coreEvent) {
      super.mouseMoved(with: event)
    }
  }

  public override func mouseDragged(with event: NSEvent) {
    guard !suppressPointerUpdates else { return }

    // print(">>> mouseDragged, self: \(ObjectIdentifier(self))")

    let coreEvent = CorePointerDragEvent(
      details: event.pointerDetails(relativeTo: self),
      deltaX: event.deltaX,
      deltaY: event.deltaY,
    )

    eventRouter.handlePointerDragged(event: coreEvent)

    if shouldPropagateEvent(coreEvent) {
      super.mouseDragged(with: event)
    }
  }

  public override func scrollWheel(with event: NSEvent) {
    let coreEvent = CorePointerWheelEvent(
      details: event.pointerDetails(relativeTo: self),
      deltaX: event.scrollingDeltaX,
      deltaY: event.scrollingDeltaY,
      hasPreciseScrollDeltas: event.hasPreciseScrollingDeltas,
    )

    eventRouter.handlePointerWheel(event: coreEvent)

    if shouldPropagateEvent(coreEvent) {
      super.scrollWheel(with: event)
    }
  }

  public override func magnify(with event: NSEvent) {
    super.magnify(with: event)

    print(">>> magnify with: \(event)")
  }

  public override func keyDown(with event: NSEvent) {
    let coreEvent = CoreKeyEvent(
      key: .init(keyCode: event.keyCode),
      modifierFlags: event.modifierFlags,
    )

    eventRouter.handleKeyDown(event: coreEvent)

    if shouldPropagateEvent(coreEvent) {
      super.keyDown(with: event)
    }
  }

  public override func keyUp(with event: NSEvent) {
    let coreEvent = CoreKeyEvent(
      key: .init(keyCode: event.keyCode),
      modifierFlags: event.modifierFlags,
    )

    eventRouter.handleKeyUp(event: coreEvent)

    if shouldPropagateEvent(coreEvent) {
      super.keyUp(with: event)
    }
  }

  public override func updateTrackingAreas() {
    super.updateTrackingAreas()

    if let trackingArea = trackingArea {
      removeTrackingArea(trackingArea)
    }

    let options: NSTrackingArea.Options = [
      .mouseEnteredAndExited,
      .mouseMoved,
      .activeAlways,
      .inVisibleRect
    ]

    let trackingArea = NSTrackingArea(
      rect: bounds,
      options: options,
      owner: self,
      userInfo: nil
    )

    addTrackingArea(trackingArea)
    self.trackingArea = trackingArea
  }

  public override func resetCursorRects() {
    super.resetCursorRects()
    if let cursor {
      addCursorRect(bounds, cursor: .from(cursor))
    }
  }

  public func tearDown() {
    rootView.subviews = { [] }
    rootView.subviewMap.removeAll()
    subviews = []
  }

  @MainActor
  @Observable
  final class LayoutState {
    var width = CGFloat.zero
    var height = CGFloat.zero
  }

  var eventRouter: EventRouter {
    routerOverrides.last ?? defaultRouter
  }

  private let rootView: CoreView
  private var trackingArea: NSTrackingArea?
  private var displayLink: CADisplayLink?
  private var layoutState = LayoutState()
  private var routerOverrides = [EventRouter]()

  private lazy var defaultRouter: EventRouter = DefaultEventRouter(
    rootView: rootView,
    onSetCursor: { [weak self] in
      self?.cursor = $0      
    }
  )

  private var cursor: Cursor? {
    didSet {
      guard cursor != oldValue else { return }
      window?.invalidateCursorRects(for: self)
    }
  }

  private lazy var debugButton = NSButton(title: "Debug", target: self, action: #selector(onDebugAction))

  private var displayLinkDrivenAnimations = Set<DisplayLinkDrivenAnimation>() {
    didSet {
      if displayLinkDrivenAnimations.isEmpty {
        if let displayLink {
          displayLink.invalidate()
          self.displayLink = nil
        }
      } else {
        if displayLink == nil {
          displayLink = displayLink(target: self, selector: #selector(onDisplayLinkStep))
          displayLink?.add(to: .current, forMode: .default)
        }
      }
    }
  }

  private func shouldPropagateEvent<Event>(_ event: Event) -> Bool where Event: CoreEvent {
    !event.handled
  }

  private func handleAnyMouseDown(with event: NSEvent) -> Bool {
    guard !suppressPointerUpdates else { return true }

    let coreEvent = CorePointerEvent(
      locationInRoot: convert(event.locationInWindow, from: nil),
      buttons: .current,
      modifierFlags: event.modifierFlags,
    )

    eventRouter.handlePointerDown(event: coreEvent)
    return shouldPropagateEvent(coreEvent)
  }

  private func handleAnyMouseUp(with event: NSEvent) -> Bool {
    guard !suppressPointerUpdates else { return true }

    let coreEvent = CorePointerEvent(
      locationInRoot: convert(event.locationInWindow, from: nil),
      buttons: .current,
      modifierFlags: event.modifierFlags,
    )

    eventRouter.handlePointerUp(event: coreEvent)
    return shouldPropagateEvent(coreEvent)
  }

  @objc
  private func onDisplayLinkStep() {
    guard let displayLink else { return }
    for displayLinkDrivenAnimation in displayLinkDrivenAnimations {
      if let current = displayLinkDrivenAnimation.layer.presentation()?.value {
        let predicted = {
          guard let lastValue = displayLinkDrivenAnimation.lastValue else { return current }
          let dt = displayLink.duration
          let velocity = (current - lastValue) / dt
          return clamp(current + velocity * dt, 0, 1)
        }()
        displayLinkDrivenAnimation.lastValue = current
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLinkDrivenAnimation.step(predicted)
        CATransaction.commit()
      }
    }
  }

  @objc
  private func onDebugAction() {
    print(">>> debug action!")
    rootView.subviews = { [] }
    rootView.subviewMap.removeAll()
  }

  @objc
  private func onWindowBackingPropertiesChanged(_: Notification) {
    context.backingScaleFactor = window?.backingScaleFactor ?? 1
  }
}

extension NSHostingView: CoreViewContext.Delegate {
  public var containingNSView: NSView {
    self
  }

  public func didFlushUpdates() {
    guard !suppressPointerUpdates else { return }
    guard let pointerDetails = NSEvent.currentPointerDetails(relativeTo: self) else { return }
    eventRouter.updateHoveredViews(event: .init(details: pointerDetails))
  }

  public func sampleAnimation(
    _ animation: CABasicAnimation,
    step: @escaping (CGFloat) -> Void,
    completion: @escaping () -> Void,
  ) {
    let layer = SamplingLayer()
    self.layer?.addSublayer(layer)
    let displayLinkDrivenAnimation = DisplayLinkDrivenAnimation(layer: layer, step: step, completion: { [weak self] in
      guard let self else { return }
      displayLinkDrivenAnimations.remove($0)
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      completion()
      CATransaction.commit()
    })
    displayLinkDrivenAnimations.insert(displayLinkDrivenAnimation)
    animation.fromValue = 0
    animation.toValue = 1
    animation.keyPath = "value"
    animation.delegate = displayLinkDrivenAnimation
    layer.add(animation, forKey: "\(displayLinkDrivenAnimation.id)")
    layer.value = 1
  }

  public func addEmbeddedNSView(_ view: NSView) {
    addSubview(view)
  }

  public func updateEmbeddedViews(_ views: [NSView]) {
    print(">>> updateEmbeddedViews, views.count: \(views.count)")

    let viewsBeingRemoved = subviews.filter { !views.contains($0) }
    print(">>> viewsBeingRemoved.count: \(viewsBeingRemoved.count)")

    let moveFirstResponder = {
      if let firstResponder = window?.firstResponder as? NSView {
        for view in viewsBeingRemoved {
          if firstResponder === view || firstResponder.isDescendant(of: view) {
            return true
          }
        }
      }
      return false
    }()

    subviews = views

    print(">>> should move first responder: \(moveFirstResponder)")

    if moveFirstResponder, let window {
      window.makeFirstResponder(self)
      // updateTrackingAreas()

      print(">>> window.firstResponder: \(window.firstResponder.flatMap { ObjectIdentifier($0) }), window is key: \(window.isKeyWindow)")
    }

    // subviews = views
  }
}

extension NSHostingView: HostingView {
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

@MainActor
private final class DisplayLinkDrivenAnimation: NSObject {
  init(layer: SamplingLayer, step: @escaping (CGFloat) -> Void, completion: @escaping (DisplayLinkDrivenAnimation) -> Void) {
    self.layer = layer
    self.step = step
    self.completion = completion
  }

  let layer: SamplingLayer
  let step: (CGFloat) -> Void
  let completion: (DisplayLinkDrivenAnimation) -> Void
  var lastValue: CGFloat?
}

extension DisplayLinkDrivenAnimation: @MainActor Identifiable {
  var id: ObjectIdentifier { .init(self) }
}

extension DisplayLinkDrivenAnimation: @MainActor CAAnimationDelegate {
  func animationDidStop(_: CAAnimation, finished: Bool) {
    completion(self)
  }
}

private final class SamplingLayer: CALayer {
  @NSManaged var value: CGFloat
}

extension NSEvent {
  @MainActor
  fileprivate func pointerDetails(relativeTo view: NSView) -> PointerEventDetails {
    .init(
      location: view.convert(locationInWindow, from: nil),
      buttons: .current,
      modifiers: modifierFlags,
    )
  }

  @MainActor
  fileprivate class func currentPointerDetails(relativeTo view: NSView) -> PointerEventDetails? {
    view.window.flatMap { window in
      .init(
        location: view.convert(window.mouseLocationOutsideOfEventStream, from: nil),
        buttons: .current,
        modifiers: modifierFlags,
      )
    }
  }
}

extension PointerButtons {
  fileprivate static var current: Self {
    var result = PointerButtons()

    let buttons = NSEvent.pressedMouseButtons
    if buttons & (1 << 0) != 0 {
      result.insert(PointerButtons.left)
    }
    if buttons & (1 << 1) != 0 {
      result.insert(PointerButtons.right)
    }
    if buttons & (1 << 2) != 0 {
      result.insert(PointerButtons.middle)
    }

    return result
  }
}

#endif