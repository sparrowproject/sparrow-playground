#if os(Windows)
import Foundation
import SparrowUICore
import SparrowUIFoundation
import WinAppSDK
import WindowsFoundation
import WinSDK
import WinUI

@MainActor
struct _PopoverModifier<PopoverContent: View> {
  let isPresented: Binding<Bool>
  let preferredAnchor: @MainActor () -> PositionalAnchor
  let style: @MainActor () -> PopoverStyle
  var dismissOnPointerExit: Bool = false
  let content: @MainActor () -> PopoverContent
}

extension _PopoverModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .overlay(
        FlyoutAnchorRepresentable<PopoverContent>(
          isPresented: isPresented,
          preferredAnchor: preferredAnchor,
          style: style,
          dismissOnPointerExit: dismissOnPointerExit,
          content: self.content,
        )
      )
  }
}

private struct FlyoutAnchorRepresentable<PopoverContent: View>: WinUIElementRepresentable {
  let isPresented: Binding<Bool>
  let preferredAnchor: @MainActor () -> PositionalAnchor
  let style: @MainActor () -> PopoverStyle
  let dismissOnPointerExit: Bool
  let content: @MainActor () -> PopoverContent

  func makeUIElement(context: CoreViewContext, associatedView anchorView: CoreView) -> FlyoutAnchor<PopoverContent> {
    .init(
      context: context,
      anchorView: anchorView,
      isPresented: isPresented,
      preferredAnchor: preferredAnchor,
      style: style,
      dismissOnPointerExit: dismissOnPointerExit,
      content: content,
    )
  }

  static func tearDownUIElement(_ flyoutAnchor: FlyoutAnchor<PopoverContent>) {
    flyoutAnchor.contentView.tearDown()
  }
}

@MainActor
private final class FlyoutAnchor<PopoverContent: View>: Grid {
  init(
    context: CoreViewContext,
    anchorView: CoreView,
    isPresented: Binding<Bool>,
    preferredAnchor: @MainActor @escaping () -> PositionalAnchor,
    style: @MainActor @escaping () -> PopoverStyle,
    dismissOnPointerExit: Bool,
    content: @MainActor @escaping () -> PopoverContent,
  ) {
    @State var contentSize = CGSize.zero
    
    let contentView = WinUIHostingView(
      content: PopoverContentContainer(content: content, isPresented: isPresented, contentSize: $contentSize),
      context: .init(derivedFrom: context),
    )

    self.contentView = contentView
    self.isPresented = isPresented
    super.init()

    let scheduler = context.scheduler

    // Redirect input events from the anchor view to the content view. This creates a cycle
    // that is broken when the flyout is closed.
    let anchorHostingView = context.delegate as! HostingView
    let eventMapper = EventMapper(from: anchorHostingView, to: contentView)

    let flyout = CustomFlyout()
    self.flyout = flyout
    flyout.presenter.content = contentView
    flyout.shouldConstrainToRootBounds = false
    flyout.placement = .auto
    flyout.areOpenCloseAnimationsEnabled = false

    flyout.presenter.background = SolidColorBrush(CoreColor.clear.value)
    flyout.presenter.padding = .init(uniform: 0)

    flyout.closed.addHandler { _, _ in
      isPresented.set(false)
    }

    func tryReveal() {
      // Defer the reveal until content size is known.
      if isPresented.get(), contentSize != .zero {
        flyout.reveal()
        contentView.whenLoaded { [weak self] in
          guard let self else { return }
          let appWindow = contentView.appWindow
          print(">>> contentView is loaded, containing window position: \(appWindow?.position), size: \(appWindow?.size)")
          if !didInstallEventMapper {
            didInstallEventMapper = true
            anchorHostingView.pushEventRouter(eventMapper)
          }
        }
        if dismissOnPointerExit {
          trackPointerExit(anchorView: anchorView)
        }
      }
    }

    scheduler.onChange(
      of: { isPresented.get() },
      perform: { [weak self] isPresented in
        guard let self else { return }
        guard isPresented != self.isShowing else { return }
        self.isShowing = isPresented
        if isPresented {
          try! flyout.showAt(self, flyoutShowOptions(for: preferredAnchor()))
          tryReveal()
        } else {
          if didInstallEventMapper {
            didInstallEventMapper = false
            anchorHostingView.popEventRouter(eventMapper)
          }
          try! flyout.hide()
          if let monitor {
            monitor.stop()
            self.monitor = nil
          }
        }
      },
      cancelWhen: Weak(self).isDiscarded,
    )

    scheduler.onChange(
      of: { contentSize },
      perform: {
        contentView.width = $0.width
        contentView.height = $0.height
        tryReveal()
      },
      cancelWhen: Weak(self).isDiscarded,
    )

    scheduler.onChange(
      of: { style().backdropStyle() },
      perform: {
        flyout.backdropStyle = $0
      },
      cancelWhen: Weak(self).isDiscarded,
    )

    scheduler.onChange(
      of: { style().borderStyle() },
      perform: {
        flyout.borderStyle = $0
      },
      cancelWhen: Weak(self).isDiscarded,
    )

    scheduler.onChange(
      of: { style().cornerStyle() },
      perform: {
        flyout.cornerStyle = $0
      },
      cancelWhen: Weak(self).isDiscarded,
    )
  }
 
  let contentView: WinUIHostingView<PopoverContentContainer<PopoverContent>>
  var isPresented: Binding<Bool>
  var transientZoneTask: Task<Void, Never>?
  var lastLocationOnScreen: DisplayPoint?

  private var flyout: CustomFlyout?
  private var isShowing = false
  private var didInstallEventMapper = false
  private var monitor: MouseMonitor?

  private func flyoutShowOptions(for anchor: PositionalAnchor) -> FlyoutShowOptions {
    let options = FlyoutShowOptions()

    // TODO: Consider inspecting the display ourselves to revise our preference here
    // using fallback options similar to what is used on macOS. This way we are more
    // precise in the behavior we want instead of accepting what WinUI would do.
    options.placement = .from(anchor)

    // Use precise positioning to prevent the implicit gap WinUI would otherwise insert
    // between the flyout and the anchor element.
    let targetPoint = anchor.targetPoint
    options.position = .init(
      x: Float(actualWidth * targetPoint.x),
      y: Float(actualHeight * targetPoint.y),
    )

    // But add an exclusion rect corresponding to the element size so that WinUI does not
    // failover to positioning the flyout on top of the anchor element.
    if anchor.target == .bounds {
      options.exclusionRect = .init(
        x: 0,
        y: 0,
        width: Float(actualWidth),
        height: Float(actualHeight),
      )
    }

    return options
  }

  private func trackPointerExit(anchorView: CoreView) {
    let monitor = MouseMonitor { [weak self] in
      guard let self else { return }
      handlePointerUpdate(locationOnScreen: $0, anchorView: anchorView)
    }
    self.monitor = monitor

    monitor.start()
  }
}

extension FlyoutAnchor: _PopoverImpl {
  var windowRect: DisplayRect? {
    // NOTE: Returning the location of `presenter.appWindow` on screen does not work as
    // the `AppWindow` returned is for the top-level window and not the popup. We can
    // avoid needing to find the actual HWND for the popup by using coordinate transforms.

    guard
      let presenter = flyout?.presenter,
      let hwnd = presenter.appWindow?.getHWND()
    else {
      return nil
    }

    let transform = try! presenter.transformToVisual(nil)!

    let rootPoint = try! transform.transformPoint(
      Point(x: 0, y: 0)
    )

    let dpi = GetDpiForWindow(hwnd)
    let scale = Double(dpi) / 96.0

    var point = POINT(
      x: LONG((rootPoint.x * Float(scale)).rounded()),
      y: LONG((rootPoint.y * Float(scale)).rounded()),
    )

    ClientToScreen(hwnd, &point)

    return .init(
      x: point.x,
      y: point.y,
      width: Int32((presenter.actualWidth * scale).rounded()),
      height: Int32((presenter.actualHeight * scale).rounded()),
    )
  }

  var state: _PopoverState { self }
}

extension FlyoutAnchor: _PopoverState {}

private struct PopoverContentContainer<PopoverContent: View>: View {
  let content: @MainActor () -> PopoverContent
  @Binding var isPresented: Bool
  @Binding var contentSize: CGSize

  var body: some View {
    // Only create the popover content when presented. This is for parity with the
    // behavior on macOS, and it also means that the content can use `onAppear` to
    // custom popover content when shown.
    IfLet(isPresented ? true : nil, id: \.self) { _ in
      content()
        .readSize(to: _contentSize)
    }
  }
}

private final class CustomFlyout: FlyoutBase {
  var backdropStyle: WindowBackdropStyle? {
    didSet {
      guard backdropStyle != oldValue else { return }
      systemBackdrop = backdropStyle?.systemBackdrop ?? nil
    }
  }

  var borderStyle: WindowBorderStyle? {
    didSet {
      guard borderStyle != oldValue else { return }

      let borderWidth: Double =
        switch borderStyle ?? .none {
        case .default:
          1
        case .none:
          0
        }
      presenter.borderThickness = .init(uniform: borderWidth)

      presenter.isDefaultShadowEnabled = borderStyle == .default
    }
  }

  var cornerStyle: WindowCornerStyle? {
    didSet {
      guard cornerStyle != oldValue else { return }
      presenter.cornerRadius = .init(uniform: cornerStyle?.radius ?? 0)
    }
  }

  func reveal() {
    presenter.opacity = 1
  }

  override func createPresenter() -> FlyoutPresenter {
    presenter
  }

  private(set) lazy var presenter: FlyoutPresenter = {
    let presenter = FlyoutPresenter()
    presenter.opacity = 0
    return presenter
  }()
}

extension WindowBackdropStyle {
  var systemBackdrop: SystemBackdrop? {
    switch self {
    case .transparent:
      nil

    case .acrylic:
      DesktopAcrylicBackdrop()

    case .mica:
      MicaBackdrop(kind: .base)

    case .micaAlt:
      MicaBackdrop(kind: .baseAlt)
    }
  }
}

#endif