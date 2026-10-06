#if os(macOS)
import AppKit
import SparrowUICore
import SparrowUIFoundation

@MainActor
struct _PopoverModifier<Content: View> {
  let isPresented: Binding<Bool>
  let preferredAnchor: @MainActor () -> PositionalAnchor
  let style: @MainActor () -> PopoverStyle
  var dismissOnPointerExit: Bool = false
  let content: @MainActor () -> Content

  fileprivate let windowDelegate = WindowDelegate()

  @State private var eventMapper: EventMapper?
  @State private var eventInterceptor: EventInterceptor?
  @State private var window: NSWindow?
  @State private var contentSize = CGSize.zero
  @State private var eventMonitor: Any?

  let state: _PopoverState = _PopoverModifierState()

  var windowRect: DisplayRect? {
    window?.frame
  }
}

final class _PopoverModifierState: _PopoverState {
  var transientZoneTask: Task<Void, Never>?
  var lastLocationOnScreen: DisplayPoint?
}

extension _PopoverModifier: ViewModifier {
  typealias Body = Never
}

extension _PopoverModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onChange(
      of: { isPresented.get() },
      perform: { [weak view] isPresented in
        guard let view else { return }
        if isPresented {
          showIfNeeded(anchorView: view)
        } else {
          hideIfNeeded(anchorView: view)
        }
      },
      cancellable: false,
    )
  }

  private func showIfNeeded(anchorView: CoreView) {
    guard window == nil else {
      return
    }

    let window = Self.makeWindow()

    // print(">>> CREATING window: \(ObjectIdentifier(window))")

    window.delegate = windowDelegate
    window.configureAsChild(ofWindowContaining: anchorView)

    // TODO: Inherit `scheduler` and other properties?
    let contentView = NSHostingView(
      content: ModalPanelContentView(
        contentSize: $contentSize,
        content: content(),
      ),
      context: .init(derivedFrom: anchorView.context),
    )

    // Redirect input events from the anchor view to the content view. This creates a cycle
    // that is broken by `hideIfNeeded`
    let anchorHostingView = anchorView.context.delegate as! HostingView
    let eventMapper = EventMapper(from: anchorHostingView, to: contentView)
    self.eventMapper = eventMapper
    anchorHostingView.pushEventRouter(eventMapper)

    if dismissOnPointerExit {
      let eventInterceptor = EventInterceptor(sink: contentView.eventRouter)
      eventInterceptor.onPointerDragged = { event in
        let locationOnScreen = window.convertPoint(toScreen: contentView.convert(event.locationInRoot, to: nil))
        handlePointerUpdate(locationOnScreen: locationOnScreen, anchorView: anchorView)
        return .allow
      }
      self.eventInterceptor = eventInterceptor
      contentView.pushEventRouter(eventInterceptor)
    }

    let contentContainerView = WindowContentContainerView()
    contentContainerView.contentView = contentView

    window.contentView = contentContainerView

    anchorView.context.scheduler.onChange(
      of: { style().backdropStyle() },
      perform: {
        contentContainerView.backdropStyle = $0
      },
      cancelWhen: {
        self.window == nil
      }
    )

    anchorView.context.scheduler.onChange(
      of: { style().borderStyle() },
      perform: {
        contentContainerView.borderStyle = $0
      },
      cancelWhen: {
        self.window == nil
      }
    )

    anchorView.context.scheduler.onChange(
      of: { style().cornerStyle() },
      perform: {
        contentContainerView.cornerStyle = $0
      },
      cancelWhen: {
        self.window == nil
      }
    )

    anchorView.context.scheduler.onChange(
      of: { [weak anchorView] () -> CGRect? in
        guard let anchorView else { return nil }
        return Self.computeChildWindowFrame(
          contentSize: contentSize,
          anchoredAt: Self.computeAnchorsToConsider(for: preferredAnchor()),
          relativeTo: anchorView,
        )
      },
      perform: { frame in
        if let frame {
          window.setFrame(frame, display: true, animate: false)
        }
      },
      cancelWhen: {
        self.window == nil
      }
    )

    window.makeKeyAndOrderFront(nil)

    windowDelegate.onResignedFocus = {
      if window.childWindows?.isEmpty == false {
        for child in window.childWindows ?? [] {
          print(">>> child \(ObjectIdentifier(child)) is key: \(child.isKeyWindow)")
        }
        return
      }

      // Run this immediately to handle the case of clicking and dragging the window title bar.
      window.orderOut(nil)

      print(">>> onResignedFocus, setting isPresented to false")
      isPresented.set(false)
    }

    self.window = window

    if dismissOnPointerExit {
      trackPointerExit(anchorView: anchorView)
    }
  }

  private func hideIfNeeded(anchorView: CoreView) {
    guard let window else { return }

    // print(">>> DESTROYING window: \(ObjectIdentifier(window))")

    windowDelegate.onResignedFocus = nil

    // (window.contentView as! WindowContentContainerView).contentView = nil
    window.contentView = nil
    window.close()
    self.window = nil

    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }

    if let eventMapper {
      (anchorView.context.delegate as! HostingView).popEventRouter(eventMapper)
      self.eventMapper = nil
    }
  }

  private func trackPointerExit(anchorView: CoreView) {
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
    }
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { event in
      if let window = event.window {
        handlePointerUpdate(
          locationOnScreen: window.convertPoint(toScreen: event.locationInWindow),
          anchorView: anchorView,
        )
      }
      return event
    }
  }

  static func makeWindow() -> NSWindow {
    let window = ChildNSWindow(
      contentRect: .zero,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true

    window.isReleasedWhenClosed = false
    return window
  }

  static func computeChildWindowFrame(
    contentSize: CGSize,
    anchoredAt anchors: [PositionalAnchor],
    relativeTo anchorView: CoreView,
  ) -> DisplayRect {
    guard let parentWindow = anchorView.context.containingNSWindow else {
      assertionFailure("No parent window!")
      return .zero
    }

    let anchorRect = anchorView.rectInRootView ?? .zero

    // These rects are using a top-left origin. Need to flip.
    let candidateContentRects = anchors.map {
      $0.computeRect(ofSize: contentSize, relativeTo: anchorRect)
    }
    
    let candidateWindowRects: [CGRect] = candidateContentRects.map {
      guard let containingNSView = anchorView.context.containingNSView else {
        assertionFailure("No containing view!")
        return .zero
      }
      return containingNSView.convert($0, to: nil)
    }
    
    let candidateRects = candidateWindowRects.map {
      parentWindow.convertToScreen($0)
    }

    guard let screen = parentWindow.screen else {
      return candidateRects[0]
    }

    let screenFrame = screen.visibleFrame

    var bestRect = candidateRects[0]
    var bestArea = bestRect.intersection(screenFrame).area

    for rect in candidateRects[1...] {
      let area = rect.intersection(screenFrame).area
      if area > bestArea {
        bestRect = rect
        bestArea = area
      }
    }

    return bestRect
  }

  private static func computeAnchorsToConsider(for anchor: PositionalAnchor) -> [PositionalAnchor] {
    let fallbackPlacements: [PositionalAnchor.Placement] =
      switch anchor.placement {
      case .above(let alignment):
        [
          .above(alignment: alignment.flipped),
          .below(alignment: alignment),
          .below(alignment: alignment.flipped),
        ]
      case .below(let alignment):
        [
          .below(alignment: alignment.flipped),
          .above(alignment: alignment),
          .above(alignment: alignment.flipped),
        ]
      case .before(let alignment):
        [
          .before(alignment: alignment.flipped),
          .after(alignment: alignment),
          .after(alignment: alignment),
        ]
      case .after(let alignment):
        [
          .after(alignment: alignment.flipped),
          .before(alignment: alignment),
          .before(alignment: alignment.flipped),
        ]
      }  
    return [anchor] + fallbackPlacements.map { .init(target: anchor.target, placement: $0) }
  }
}

extension _PopoverModifier: _PopoverImpl {}

private struct ModalPanelContentView<Content: View>: View {
  @Binding var contentSize: CGSize
  let content: Content

  var body: some View {
    Group {
      content
        .readSize(to: _contentSize)
    }
  }
}

private final class ChildNSWindow: NSPanel {
  override var canBecomeKey: Bool {
    true
  }
}

private final class WindowDelegate: NSObject, NSWindowDelegate {
  var onResignedFocus: (() -> Void)?

  public func windowDidResignKey(_: Notification) {
    onResignedFocus?()
  }
}

private final class WindowContentContainerView: NSView {
  var contentView: NSView? {
    didSet {
      guard contentView !== oldValue else { return }

      let parentView = effectView ?? self

      if let contentView {
        parentView.subviews = [contentView]
      } else {
        parentView.subviews = []
      }
    }
  }

  var borderStyle: WindowBorderStyle? {
    didSet {
      guard borderStyle != oldValue else { return }
      window?.hasShadow = borderStyle == .default
    }
  }

  var backdropStyle: WindowBackdropStyle? {
    didSet {
      guard backdropStyle != oldValue else { return }

      if case .material(let material, let blendingMode, let state) = backdropStyle {
        let effectView = effectView ?? {
          let view = NSVisualEffectView()
          self.effectView = view
          return view
        }()
        effectView.material = material
        effectView.blendingMode = blendingMode
        effectView.state = state
      } else {
        effectView = nil
      }
    }
  }

  var cornerStyle: WindowCornerStyle? {
    didSet {
      guard cornerStyle != oldValue else { return }
      cornerRadius = cornerStyle?.radius ?? 0
    }
  }

  var effectView: NSVisualEffectView? {
    didSet {
      guard effectView !== oldValue else { return }

      contentView?.removeFromSuperview()

      if let effectView {
        subviews = [effectView]
      }

      if let contentView {
        (effectView ?? self).subviews = [contentView]
      }
    }
  }

  var cornerRadius: CGFloat = 0 {
    didSet {
      wantsLayer = true
      if cornerRadius > 0 {
        layer?.mask = shapeLayer
        needsLayout = true
      } else {
        layer?.mask = nil
      }
    }
  }

  override func layout() {
    super.layout()

    effectView?.frame = bounds
    contentView?.frame = bounds

    if cornerRadius > 0 {
      shapeLayer.path = Path(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
  }

  private lazy var shapeLayer = CAShapeLayer()
}

extension NSWindow {
  fileprivate func configureAsChild(ofWindowContaining anchorView: CoreView) {
    guard let parentWindow = anchorView.context.containingNSWindow else {
      assertionFailure("No parent window!")
      return
    }
    parentWindow.addChildWindow(self, ordered: .above)
  }
}

#endif
