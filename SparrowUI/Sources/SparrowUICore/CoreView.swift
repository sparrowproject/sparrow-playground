import Foundation
import Observation
import OrderedCollections
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WindowsFoundation
import WinAppSDK
import WinSDK
#endif

/// A `CoreView` is 1:1 with `CALayer` / WinAppSDK `Visual`.
@MainActor
open class CoreView {
  public init(context: CoreViewContext) {
    self.context = context
    // print(">>> creating CoreView @ \(id) with state: \(ObjectIdentifier(state))")

    // This one is special and not part of `bindState` since it controls whether we are
    // observing other state.
    bind({ [state] in state.effectiveVisible }, to: \CoreView._visible, cancellable: false)

    bindState()
  }

  @MainActor deinit {
    // print(">>> destroying CoreView @ \(id)")

    subviews = { [] } // Break cycles. TODO: Investigate if there is a better approach!

    #if os(Windows)
    // WinAppSDK will destroy any child visual that is owned by this visual when it is destroyed,
    // so it is important that we detach all child visuals to allow them to each be destroyed
    // independently.
    // XXX
    // try? visual.children.removeAll()
    #endif
  }

  public struct HitTestProperty: OptionSet, Sendable {
    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public let rawValue: Int32

    public static let pointerDown = HitTestProperty(rawValue: 1 << 0)
    public static let pointerUp = HitTestProperty(rawValue: 1 << 1)
    public static let pointerEnter = HitTestProperty(rawValue: 1 << 2)
    public static let pointerExit = HitTestProperty(rawValue: 1 << 3)
    public static let pointerMoved = HitTestProperty(rawValue: 1 << 4)
    public static let pointerDragged = HitTestProperty(rawValue: 1 << 5)
    public static let pointerWheel = HitTestProperty(rawValue: 1 << 6)
    public static let keyDown = HitTestProperty(rawValue: 1 << 7)
    public static let keyUp = HitTestProperty(rawValue: 1 << 8)
    public static let hasCursor = HitTestProperty(rawValue: 1 << 9)

    public static let allCases: [HitTestProperty] = [
      .pointerDown,
      .pointerUp,
      .pointerEnter,
      .pointerExit,
      .pointerMoved,
      .pointerDragged,
      .pointerWheel,
      .keyDown,
      .keyUp,
      .hasCursor,
    ]
  }

  public let context: CoreViewContext
  public private(set) weak var superview: CoreView?

  private(set) lazy var state = makeState()

  // TODO: add other properties:
  // - zIndex

  public var overlay: @MainActor () -> CoreView? {
    get { state.overlay }
    set { state.overlay = newValue }
  }

  // Order implies z-order for hit testing. Last element is top-most.
  // An overlay, if specified, is not part of `subviews` and is always above.
  // TODO: Switch to `OrderedSet` for performance.
  public var subviews: @MainActor () -> [CoreView] {
    get { state.subviews }
    set { state.subviews = newValue }
  }

  public var mask: @MainActor () -> CoreView? {
    get { state.mask }
    set { state.mask = newValue }
  }

  public var offsetX: @MainActor () -> CGFloat {
    get { state.offsetX }
    set { state.offsetX = newValue }
  }

  public var offsetY: @MainActor () -> CGFloat {
    get { state.offsetY }
    set { state.offsetY = newValue }
  }

  public var width: (@MainActor () -> CGFloat)? {
    get { state.width }
    set { state.width = newValue }
  }

  public var height: (@MainActor () -> CGFloat)? {
    get { state.height }
    set { state.height = newValue }
  }

  public var alignment: @MainActor () -> Alignment {
    get { state.alignment }
    set { state.alignment = newValue }
  }

  public var padding: [@MainActor () -> EdgeInsets] {
    get { state.padding }
    set { state.padding = newValue }
  }

  public var opacity: @MainActor () -> CGFloat {
    get { state.opacity }
    set { state.opacity = newValue }
  }

  public var scale: @MainActor () -> Double {
    get { state.scale }
    set { state.scale = newValue }
  }

  public var shadow: @MainActor () -> CoreShadow? {
    get { state.shadow }
    set { state.shadow = newValue }
  }

  public var clipToBounds: @MainActor () -> Bool {
    get { state.clipToBounds }
    set { state.clipToBounds = newValue }
  }

  public var allowsAnimation: @MainActor () -> Bool {
    get { state.allowsAnimation }
    set { state.allowsAnimation = newValue }
  }

  public var allowsHitTesting: @MainActor () -> Bool {
    get { state.allowsHitTesting }
    set { state.allowsHitTesting = newValue }
  }

  public var acceptsFocus: @MainActor () -> Bool {
    get { state.acceptsFocus }
    set { state.acceptsFocus = newValue }
  }

  public var visible: @MainActor () -> Bool {
    get { state.visible }
    set { state.visible = newValue }
  }

  public var cursor: @MainActor () -> Cursor? {
    get { state.cursor }
    set { state.cursor = newValue }
  }

  public var colorScheme: @MainActor () -> ColorScheme? {
    get { state.colorScheme }
    set { state.colorScheme = newValue }
  }

  public let onPointerDown = CoreEventHandlerSet<CorePointerEvent>()
  public let onPointerUp = CoreEventHandlerSet<CorePointerEvent>()
  public let onPointerEntered = CoreEventHandlerSet<CorePointerEvent>()
  public let onPointerExited = CoreEventHandlerSet<CorePointerEvent>()
  public let onPointerMoved = CoreEventHandlerSet<CorePointerEvent>()
  public let onPointerDragged = CoreEventHandlerSet<CorePointerDragEvent>()
  public let onPointerWheel = CoreEventHandlerSet<CorePointerWheelEvent>()
  public let onKeyDown = CoreEventHandlerSet<CoreKeyEvent>()
  public let onKeyUp = CoreEventHandlerSet<CoreKeyEvent>()

  /// TODO: Consider how to make this internal only. Used by `NSHostingView`.
  public var subviewMap: [AnyHashable: CoreView] = [:]

  public var globalPositionGetter: @MainActor () -> CGPoint? {
    { [state] in state.globalPosition }
  }

  public var effectiveWidthGetter: @MainActor () -> CGFloat {
    { [state] in state.effectiveWidth }
  }

  public var effectiveHeightGetter: @MainActor () -> CGFloat {
    { [state] in state.effectiveHeight }
  }

  public var effectiveSizeGetter: @MainActor () -> CGSize {
    { [state] in state.effectiveSize }
  }

  public var effectiveColorSchemeGetter: @MainActor () -> ColorScheme {
    { [state, context] in
      state.effectiveColorScheme ?? context.colorScheme
    }
  }

  /// Indicates if this view has a configured cursor.
  public var hasCursor: Bool {
    _cursor != nil
  }

  public var activeCursor: Cursor? {
    _cursor
  }

  /// If non-nil, the _cursor and any changes to it will be passed to this function.
  public var reportCursor: ((Cursor?) -> Void)? {
    didSet {
      reportCursor?(_cursor)
    }
  }

  #if os(macOS)
  public private(set) lazy var layer: CALayer = makeLayer()
  func makeLayer() -> CALayer {
    .init()
  }
  #elseif os(Windows)
  public private(set) lazy var visual: SpriteVisual = {
    let visual = try! context.compositor.createSpriteVisual()!
    configureVisual(visual)
    visual.brush = contentBrush()
    return visual
  }()
  #endif

  /// The root view will never be made a subview of another view.
  public func configureAsRootView() {
    state.isRoot = true
  }

  public func findFocusableView() -> CoreView? {
    if _acceptsFocus {
      return self
    }
    // Similar to hit testing, prefer views that are higher in the z-order.
    for subview in _subviews.reversed() {
      if let result = subview.findFocusableView() {
        return result
      }
    }
    return nil
  }

  @MainActor
  @Observable
  class State {
    var isRoot = false
    weak var containerState: State?

    var overlay: @MainActor () -> CoreView? = { nil }
    var subviews: @MainActor () -> [CoreView] = { [] }
    var mask: @MainActor () -> CoreView? = { nil }

    var offsetX: @MainActor () -> CGFloat = { .zero }
    var offsetY: @MainActor () -> CGFloat = { .zero }

    // Adds padding intrinsicSize.
    var padding: [@MainActor () -> EdgeInsets] = []

    // When padding + intrinsicSize is less than availableSize, used to set position.
    var alignment: @MainActor () -> Alignment = { .topLeading }

    // Explicit dimensions.
    var width: (@MainActor () -> CGFloat)?
    var height: (@MainActor () -> CGFloat)?

    // If the content of the view has an intrinsic size.
    var intrinsicSize: CGSize?

    var opacity: @MainActor () -> CGFloat = { 1 }
    var scale: @MainActor () -> Double = { 1 }
    var shadow: @MainActor () -> CoreShadow? = { nil }
    var clipToBounds: @MainActor () -> Bool = { false }
    var allowsAnimation: @MainActor () -> Bool = { true }
    var allowsHitTesting: @MainActor () -> Bool = { true }
    var acceptsFocus: @MainActor () -> Bool = { false }
    var visible: @MainActor () -> Bool = { true }
    var cursor: @MainActor () -> Cursor? = { nil }
    var colorScheme: @MainActor () -> ColorScheme? = { nil }

    var effectiveSubviews: [CoreView] {
      subviews() + (overlay().flatMap { [$0] } ?? [])
    }

    // These are internal state so that expressions used to calculate them do not
    // need to be re-computed. This helps avoid degenerate performance issues with
    // deeply nested views.
    var effectiveWidth: CGFloat = 0
    var effectiveHeight: CGFloat = 0

    var effectivePositionX: CGFloat = 0
    var effectivePositionY: CGFloat = 0

    func computePadding() -> EdgeInsets {
      var result = EdgeInsets.zero
      for padding in padding {
        let padding = padding()
        result = EdgeInsets(
          leading: result.leading + padding.leading,
          trailing: result.trailing + padding.trailing,
          top: result.top + padding.top,
          bottom: result.bottom + padding.bottom,
        )
      }
      return result
    }

    func computeEffectivePositionX() -> CGFloat {
      let padding = computePadding()
      let alignmentOffsetX =
        switch alignment() {
        case .leading, .topLeading, .bottomLeading:
          padding.leading
        case .center, .top, .bottom:
          (availableWidth - effectiveWidth - padding.leading - padding.trailing) / 2 + padding.leading
        case .trailing, .topTrailing, .bottomTrailing:
          availableWidth - effectiveWidth - padding.trailing
        }
      return alignmentOffsetX + offsetX()
    }

    func computeEffectivePositionY() -> CGFloat {
      let padding = computePadding()
      let alignmentOffsetY =
        switch alignment() {
        case .top, .topLeading, .topTrailing:
          padding.top
        case .center, .leading, .trailing:
          (availableHeight - effectiveHeight - padding.top - padding.bottom) / 2 + padding.top
        case .bottom, .bottomLeading, .bottomTrailing:
          availableHeight - effectiveHeight - padding.bottom
        }
      return alignmentOffsetY + offsetY()
    }

    func computeEffectiveWidth() -> CGFloat {
      let padding = computePadding()
      let proposal: CGFloat =
        if let width {
          width()
        } else if let intrinsicSize {
          intrinsicSize.width
        } else if let containerWidth {
          containerWidth - padding.totalHorizontal
        } else {
          .zero
        }
      guard proposal >= 0 else {
        return .zero
      }
      return proposal
    }

    func computeEffectiveHeight() -> CGFloat {
      let padding = computePadding()
      let proposal: CGFloat =
        if let height {
          height()
        } else if let intrinsicSize {
          intrinsicSize.height
        } else if let containerHeight {
          containerHeight - padding.totalVertical
        } else {
          .zero
        }
      guard proposal >= 0 else {
        return .zero
      }
      return proposal
    }

    var effectivePosition: CGPoint {
      .init(x: effectivePositionX, y: effectivePositionY)
    }

    var effectiveSize: CGSize {
      .init(width: effectiveWidth, height: effectiveHeight)
    }

    var availableWidth: CGFloat {
      if let containerWidth {
        containerWidth
      } else {
        .zero
      }
    }

    var availableHeight: CGFloat {
      if let containerHeight {
        containerHeight
      } else {
        .zero
      }
    }

    var availableSize: CGSize {
      return .init(width: availableWidth, height: availableHeight)
    }

    var effectiveVisible: Bool {
      // If the container is not visible or if the container is not set yet, then this view
      // cannot be visible. However, if this is the root view, then that does not apply.
      (containerVisible ?? isRoot) && visible()
    }

    // Properties derived from the containing view state.

    var containerWidth: CGFloat? {
      containerState?.effectiveWidth
    }

    var containerHeight: CGFloat? {
      containerState?.effectiveHeight
    }

    var containerVisible: Bool? {
      containerState?.effectiveVisible
    }

    var globalPositionX: CGFloat? {
      guard let containerGlobalPositionX = containerState?.globalPositionX ?? (isRoot ? 0 : nil) else { return nil }
      return effectivePositionX + containerGlobalPositionX
    }

    var globalPositionY: CGFloat? {
      guard let containerGlobalPositionY = containerState?.globalPositionY ?? (isRoot ? 0 : nil) else { return nil }
      return effectivePositionY + containerGlobalPositionY
    }

    var globalPosition: CGPoint? {
      guard let globalPositionX, let globalPositionY else { return nil }
      return .init(x: globalPositionX, y: globalPositionY)
    }

    var effectiveColorScheme: ColorScheme? {
      colorScheme() ?? containerState?.effectiveColorScheme
    }
  }

  func makeState() -> State {
    .init()
  }

  func bindState() {
    cancellationToken.isCancelled = true
    cancellationToken = .init()

    bind({ [state] in state.effectiveSubviews }, to: \CoreView._subviews)
    bind({ [state] in state.mask() }, to: \CoreView._mask)
    bind({ [state] in state.effectivePosition }, to: \CoreView._position)
    bind({ [state] in state.effectiveSize }, to: \CoreView._size)
    bind({ [state] in state.availableSize }, to: \CoreView._availableSize)
    bind({ [state] in state.opacity() }, to: \CoreView._opacity)
    bind({ [state] in state.scale() }, to: \CoreView._scale)
    bind({ [state] in state.shadow() }, to: \CoreView._shadow)
    bind({ [state] in state.clipToBounds() }, to: \CoreView._clipToBounds)
    bind({ [state] in state.allowsAnimation() }, to: \CoreView._allowsAnimation)
    bind({ [state] in state.allowsHitTesting() }, to: \CoreView._allowsHitTesting)
    bind({ [state] in state.acceptsFocus() }, to: \CoreView._acceptsFocus)
    bind({ [state] in state.cursor() }, to: \CoreView._cursor)

    bind({ [state] in state.computeEffectivePositionX() }, to: \CoreView.state.effectivePositionX)
    bind({ [state] in state.computeEffectivePositionY() }, to: \CoreView.state.effectivePositionY)
    bind({ [state] in state.computeEffectiveWidth() }, to: \CoreView.state.effectiveWidth)
    bind({ [state] in state.computeEffectiveHeight() }, to: \CoreView.state.effectiveHeight)
  }

  public func hitTest(at location: CGPoint, matchingAnyOf properties: HitTestProperty) -> CoreView? {
    guard _opacity != 0, _visible, _allowsHitTesting else { return nil }

    let locationInSelf = CGPoint(
      x: location.x - _position.x,
      y: location.y - _position.y,
    )
    guard _size.contains(locationInSelf) else { return nil }

    // TODO: Should this consider z-index? Should this perform visual hit testing?
    for subview in _subviews.reversed() {
      if let result = subview.hitTest(at: locationInSelf, matchingAnyOf: properties) {
        return result
      }
    }

    guard respondsTo(anyOf: properties) else {
      return nil
    }

    return self
  }

  public func hitTestMany(at location: CGPoint, matchingAnyOf properties: HitTestProperty, addingTo result: inout OrderedSet<CoreView>) {
    guard _opacity != 0, _visible, _allowsHitTesting else { return }

    let locationInSelf = CGPoint(
      x: location.x - _position.x,
      y: location.y - _position.y,
    )
    guard _size.contains(locationInSelf) else { return }

    // Generate a z-ordered array of results, starting w/ top-most.

    for subview in _subviews.reversed() {
      subview.hitTestMany(at: locationInSelf, matchingAnyOf: properties, addingTo: &result)
    }

    if respondsTo(anyOf: properties) {
      result.append(self)
    }
  }

  public func observeSize(_ observer: @MainActor @escaping (CGSize) -> Void) {
    sizeObservers.append(observer)
  }

  public func observeAvailableSize(_ observer: @MainActor @escaping (CGSize) -> Void) {
    availableSizeObservers.append(observer)
  }

  public func onChange<Value>(
    of expression: @MainActor @escaping () -> Value,
    perform work: @MainActor @escaping (Value) -> Void,
    cancellable: Bool,
  ) {
    context.scheduler.onChange(
      of: expression,
      perform: work,
      cancelWhen: { [weak self, cancellationToken] in
        self == nil || (cancellable && cancellationToken.isCancelled)
      }
    )
  }

  public func onChange<Value>(
    of expression: @MainActor @escaping () -> Value,
    performDeferred work: @MainActor @escaping (Value) -> Void,
    cancellable: Bool,
  ) {
    context.scheduler.onChange(
      of: expression,
      performDeferred: work,
      cancelWhen: { [weak self, cancellationToken] in
        self == nil || (cancellable && cancellationToken.isCancelled)
      }
    )
  }

  public func onAppear(perform work: @escaping @MainActor () -> Void) {
    onChange(
      of: { [state] in state.effectiveVisible },
      performDeferred: {
        if $0 {
          work()
        }
      },
      cancellable: false,
    )
  }

  var animation: CoreViewAnimation? {
    guard suppressAnimationsCounter == 0 else { return nil }
    return context.scheduler.animationInstance?.animation
  }

  func bind<Value, Member, SelfType>(
    _ expression: @MainActor @escaping () -> Value,
    to member: Member,
    cancellable: Bool = true,
  ) where Member: ReferenceWritableKeyPath<SelfType, Value> {
    onChange(
      of: expression,
      perform: { [weak self] latestValue in
        guard let self else { return }
        (self as! SelfType)[keyPath: member] = latestValue
      },
      cancellable: cancellable,
    )
  }

  func setSuperview(_ superview: CoreView?) {
    guard superview !== self.superview else { return }

    // Order of operations here is pretty subtle. By scheduling this suppression before
    // updating `containerState`, we effectively schedule `onAppear` to run after we
    // have resumed animations. This way an `onAppear` handler can change state and have
    // that be driven with animations. (Any other scheduled initial state will be applied
    // normally as non-deferred updates, which is also important for animations so the
    // initial state is set properly.)
    if let superview {
      self.superview = superview
      context.scheduler.scheduleDeferredUpdate { [weak self] in
        self?.suppressAnimationsCounter -= 1
      }
      state.containerState = superview.state
    } else {
      suppressAnimationsCounter += 1
      self.superview = nil
      state.containerState = nil
      subviews = { [] } // Break cycles. TODO: Investigate if there is a better approach!
      _subviews = [] // Do it now!
    }
  }

  func sizeChanged(value: CGSize) {
    for observer in sizeObservers {
      observer(value)
    }
  }

  func availableSizeChanged(value: CGSize) {
    for observer in availableSizeObservers {
      observer(value)
    }
  }

  #if os(Windows)
  func configureVisual(_: SpriteVisual) {}
  func configureDropShadow(_: DropShadow) {}
  func contentBrush() -> CompositionBrush? { nil }
  #endif

  @MainActor
  private final class CancellationToken {
    var isCancelled = false
  }

  private enum KeyedAnimation: Hashable {
    case size
  }

  private var keyedAnimations = [KeyedAnimation: CoreViewAnimationInstance.ID]()
  private var cancellationToken = CancellationToken()
  private var sizeObservers = [(CGSize) -> Void]()
  private var availableSizeObservers = [(CGSize) -> Void]()

  #if os(Windows)
  private var contentVisual: SpriteVisual?
  private var contentVisualSurface: CompositionVisualSurface?
  private var maskBrush: CompositionMaskBrush?
  private var maskVisualSurface: CompositionVisualSurface?
  #endif

  private var _subviews: [CoreView] = [] {
    didSet {
      guard _subviews != oldValue else { return }

      #if os(macOS)
      layer.sublayers = _subviews.map(\.layer)
      #elseif os(Windows)
      applySubviewVisuals()
      #endif

      for subview in _subviews {
        subview.setSuperview(self)
      }
      for subview in oldValue where !_subviews.contains(subview) {
        subview.setSuperview(nil)
      }
    }
  }

  #if os(Windows)
  private func applySubviewVisuals() {
    let visual = contentVisual ?? visual
    try! visual.children.removeAll()
    _subviews.map(\.visual).forEach {
      try! visual.children.insertAtTop($0)
    }
  }
  #endif

  private var _mask: CoreView? {
    didSet {
      guard _mask != oldValue else { return }

      oldValue?.setSuperview(nil)

      // Set the mask as a child of this view. This way it tracks the size of this view, etc.
      _mask?.setSuperview(self)

      #if os(macOS)
      if let _mask {
        layer.mask = _mask.layer
      } else {
        layer.mask = nil
      }
      #elseif os(Windows)
      if let _mask {
        let maskBrush = maskBrush ?? {
          let brush = try! context.compositor.createMaskBrush()!
          self.maskBrush = brush
          visual.brush = brush
          return brush
        }()

        let maskVisualSurface = maskVisualSurface ?? {
          let surface = try! context.compositor.createVisualSurface()!
          self.maskVisualSurface = surface
          maskBrush.mask = try! context.compositor.createSurfaceBrush(surface)
          return surface
        }()
        maskVisualSurface.sourceVisual = _mask.visual

        // Insert `contentVisual` if needed. No need to re-create when changing the mask.
        if contentVisual == nil {
          let contentVisual = try! context.compositor.createSpriteVisual()!
          self.contentVisual = contentVisual

          try! visual.children.removeAll()
          applySubviewVisuals()
          contentVisual.brush = contentBrush()

          let contentVisualSurface = try! context.compositor.createVisualSurface()!
          self.contentVisualSurface = contentVisualSurface
          contentVisualSurface.sourceVisual = contentVisual

          maskBrush.source = try! context.compositor.createSurfaceBrush(contentVisualSurface)
        }
      } else {
        visual.brush = contentBrush()

        contentVisual = nil
        contentVisualSurface = nil
        maskVisualSurface = nil
        maskBrush = nil

        applySubviewVisuals()
      }
      #endif
    }
  }

  private var _position: CGPoint = .zero {
    didSet {
      guard _position != oldValue else { return }

      #if os(macOS)
      // CALayer.position is relative to CALayer.anchorPoint, but _position is relative
      // to the top-left origin of the frame.
      let offsetX = _position.x - layer.frame.origin.x
      let offsetY = _position.y - layer.frame.origin.y

      let position = CGPoint(x: layer.position.x + offsetX, y: layer.position.y + offsetY)

      if let animation {
        let animation = CABasicAnimation()
        animation.fromValue = layer.presentation()?.position ?? oldValue
        animation.toValue = position
        animation.keyPath = "position"
        layer.add(animation, forKey: "position")
      }
      layer.position = position
      #elseif os(Windows)
      let newValue = Vector3(x: Float(_position.x), y: Float(_position.y), z: 0)
      if let animation {
        try! visual.startAnimation(
          "Offset",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
      } else {
        visual.offset = newValue
      }
      #endif
    }
  }

  // Would be nice for this to be private?
  private var _size: CGSize = .zero {
    didSet {
      guard _size != oldValue else { return }

      #if os(macOS)
      let position = CGPoint(
        x: layer.position.x + (_size.width - oldValue.width) * layer.anchorPoint.x,
        y: layer.position.y + (_size.height - oldValue.height) * layer.anchorPoint.y,
      )

      if let animation {
        layer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = layer.presentation()?.bounds.size ?? layer.bounds.size
          $0.toValue = _size
          $0.keyPath = "bounds.size"
        }, forKey: "bounds.size")

        layer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = layer.presentation()?.position ?? layer.position
          $0.toValue = position
          $0.keyPath = "position"
        }, forKey: "position")
      }

      layer.bounds.size = _size
      layer.position = position
      #elseif os(Windows)
      let newValue = Vector2(x: Float(_size.width), y: Float(_size.height))
      if let animation {
        try! visual.startAnimation(
          "Size",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
        try! contentVisual?.startAnimation(
          "Size",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
        try! contentVisualSurface?.startAnimation(
          "SourceSize",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
        try! maskVisualSurface?.startAnimation(
          "SourceSize",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
      } else {
        visual.size = newValue
        contentVisual?.size = newValue
        contentVisualSurface?.sourceSize = newValue
        maskVisualSurface?.sourceSize = newValue
      }
      // TODO: Also need to animate this?
      visual.centerPoint = Vector3(x: newValue.x / 2, y: newValue.y / 2, z: 0)
      #endif

      sizeChanged(value: _size)
    }
  }

  private var _availableSize: CGSize = .zero {
    didSet {
      guard _availableSize != oldValue else { return }

      availableSizeChanged(value: _availableSize)
    }
  }

  private var _opacity: Double = 1.0 {
    didSet {
      guard _opacity != oldValue else { return }
      let opacity = Float(_opacity)
      #if os(macOS)
      if let animation {
        layer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = layer.opacity
          $0.toValue = opacity
          $0.keyPath = "opacity"
        }, forKey: "opacity")
      }
      layer.opacity = opacity
      #elseif os(Windows)
      let newValue = Float(_opacity)
      if let animation {
        try! visual.startAnimation(
          "Opacity",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
      } else {
        visual.opacity = newValue
      }
      #endif
    }
  }

  private var _scale: Double = 1.0 {
    didSet {
      guard _scale != oldValue else { return }
      #if os(macOS)
      let transform = CATransform3DMakeScale(_scale, _scale, 1)
      if let animation {
        layer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = oldValue
          $0.toValue = _scale
          $0.keyPath = "transform.scale"
        }, forKey: "scale")
      }
      layer.transform = transform
      #elseif os(Windows)
      let newValue = Vector3(x: Float(_scale), y: Float(_scale), z: 1)
      if let animation {
        try! visual.startAnimation(
          "Scale",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
      } else {
        visual.scale = newValue
      }
      #endif
    }
  }

  private var _shadow: CoreShadow? {
    didSet {
      guard _shadow != oldValue else { return }
      #if os(macOS)
      if let _shadow {
        layer.shadowColor = _shadow.color.value
        layer.shadowOpacity = 1
        layer.shadowRadius = _shadow.radius
        layer.shadowOffset = CGSize(width: _shadow.x, height: _shadow.y)
      } else {
        layer.shadowColor = .clear
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowOffset = .zero
      }
      #elseif os(Windows)
      if let _shadow {
        let dropShadow = try! context.compositor.createDropShadow()!
        dropShadow.color = _shadow.color.value
        dropShadow.blurRadius = Float(_shadow.radius)
        dropShadow.offset = .init(x: Float(_shadow.x), y: Float(_shadow.y), z: 0)
        configureDropShadow(dropShadow)
        visual.shadow = dropShadow
      } else {
        visual.shadow = nil
      }
      #endif
    }
  }

  private var _clipToBounds: Bool = false {
    didSet {
      guard _clipToBounds != oldValue else { return }
      // Not animated.
      #if os(macOS)
      layer.masksToBounds = _clipToBounds
      #elseif os(Windows)
      visual.clip = try! context.compositor.createInsetClip()
      #endif
    }
  }

  // This starts out positive to be balanced in `setSuperview`.
  private var suppressAnimationsCounter = 1

  private var _allowsAnimation = true {
    didSet {
      guard _allowsAnimation != oldValue else { return }
      if _allowsAnimation {
        suppressAnimationsCounter += 1
      } else {
        suppressAnimationsCounter -= 1
      }
    }
  }

  private var _allowsHitTesting = true
  private var _acceptsFocus = false

  private var _cursor: Cursor? {
    didSet {
      guard _cursor != oldValue else { return }
      reportCursor?(_cursor)
    }
  }

  private var _visible = true {
    didSet {
      guard _visible != oldValue else { return }

      // Not animated.
      #if os(macOS)
      layer.isHidden = !_visible
      #elseif os(Windows)
      visual.isVisible = _visible
      #endif

      if _visible {
        bindState()
      } else {
        cancellationToken.isCancelled = true
      }
    }
  }

  private func respondsTo(anyOf properties: HitTestProperty) -> Bool {
    HitTestProperty.allCases.filter { properties.contains($0) }.contains {
      switch $0 {
      case .pointerDown:
        !onPointerDown.isEmpty
      case .pointerUp:
        !onPointerUp.isEmpty
      case .pointerEnter:
        !onPointerEntered.isEmpty
      case .pointerExit:
        !onPointerExited.isEmpty
      case .pointerMoved:
        !onPointerMoved.isEmpty
      case .pointerDragged:
        !onPointerDragged.isEmpty
      case .pointerWheel:
        !onPointerWheel.isEmpty
      case .keyDown:
        !onKeyDown.isEmpty
      case .keyUp:
        !onKeyUp.isEmpty
      case .hasCursor:
        hasCursor
      default:
        false
      }
    }
  }
}

extension CoreView: Identifiable { }

extension CoreView: @MainActor Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension CoreView: @MainActor Equatable {
  public static func == (lhs: CoreView, rhs: CoreView) -> Bool {
    lhs.id == rhs.id
  }
}

extension CoreView {
  public var rectInRootView: CGRect? {
    guard let position = globalPositionGetter() else { return nil }
    return .init(
      origin: position,
      size: effectiveSizeGetter(),
    )
  }

  public var rectOnScreen: DisplayRect? {
    #if os(macOS)
    guard
      let containingNSView = context.containingNSView,
      let containingNSWindow = context.containingNSWindow,
      let rectInRootView
    else {
      return nil
    }
    return containingNSWindow.convertToScreen(containingNSView.convert(rectInRootView, to: nil))
    #elseif os(Windows)
    guard
      let containingUIElement = context.containingUIElement,
      let scale = containingUIElement.xamlRoot?.rasterizationScale,
      let hwnd = context.containingAppWindow?.getHWND(),
      let rectInRootView
    else {
      return nil
    }
    let transform = try! containingUIElement.transformToVisual(nil)!

    let topLeft = try! transform.transformPoint(
      .init(x: Float(rectInRootView.minX), y: Float(rectInRootView.minY))
    )
    let bottomRight = try! transform.transformPoint(
      .init(x: Float(rectInRootView.maxX), y: Float(rectInRootView.maxY))
    )

    var screenTopLeft = POINT(
      x: LONG((topLeft.x * Float(scale)).rounded()),
      y: LONG((topLeft.y * Float(scale)).rounded())
    )
    var screenBottomRight = POINT(
      x: LONG((bottomRight.x * Float(scale)).rounded()),
      y: LONG((bottomRight.y * Float(scale)).rounded())
    )

    ClientToScreen(hwnd, &screenTopLeft)
    ClientToScreen(hwnd, &screenBottomRight)

    return .init(
      x: screenTopLeft.x,
      y: screenTopLeft.y,
      width: screenBottomRight.x - screenTopLeft.x,
      height: screenBottomRight.y - screenTopLeft.y,
    )
    #endif
  }
}
