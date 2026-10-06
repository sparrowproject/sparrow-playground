#if os(macOS)
import AppKit
import SparrowUI
import SparrowUICore

struct WebContentRepresentable: NSViewRepresentable {
  init(viewModel: WebContentViewModel) {
    self.viewModel = viewModel
  }

  func makeNSView(context: CoreViewContext, associatedView _: CoreView) -> WebViewContainer {
    .init(scheduler: context.scheduler, viewModel: viewModel)
  }

  static func tearDownNSView(_: WebViewContainer) {}

  let viewModel: WebContentViewModel
}

final class WebViewContainer: NSView {
  init(scheduler: CoreScheduler, viewModel: WebContentViewModel) {
    super.init(frame: .zero)

    wantsLayer = true
    layer?.backgroundColor = NSColor.systemPink.withAlphaComponent(0.2).cgColor

    scheduler.onChange(
      of: { viewModel.selectedWebContent },
      perform: { [weak self] in
        self?.webContent = $0
      },
      cancelWhen: { [weak self] in
        self == nil
      }
    )

    scheduler.onChange(
      of: { viewModel.inputDisabled },
      perform: { [weak self] in
        self?.inputDisabled = $0
      },
      cancelWhen: { [weak self] in
        self == nil
      }
    )
  }

  required init(coder: NSCoder) {
    fatalError("not implemented!")
  }

  override func layout() {
    super.layout()
    webContent?.webView.frame = bounds
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    guard !inputDisabled else { return nil }
    return super.hitTest(point)
  }

  private var webContent: WebContent? {
    didSet {
      guard webContent !== oldValue else { return }
      (oldValue as? WebContentWK)?.isForeground = false
      (oldValue as? WebContentWK)?.inputDisabled = false
      (webContent as? WebContentWK)?.isForeground = true
      (webContent as? WebContentWK)?.inputDisabled = inputDisabled
      if let webContent {
        let webView = webContent.webView
        subviews = [webView]
      } else {
        subviews = []
      }
      clearWebContentFocusIfDisabled()
      needsLayout = true
    }
  }

  private var inputDisabled = false {
    didSet {
      guard inputDisabled != oldValue else { return }
      (webContent as? WebContentWK)?.inputDisabled = inputDisabled
      clearWebContentFocusIfDisabled()
    }
  }

  private func clearWebContentFocusIfDisabled() {
    guard
      inputDisabled,
      let window,
      let webView = webContent?.webView,
      let firstResponder = window.firstResponder as? NSView,
      firstResponder === webView || firstResponder.isDescendant(of: webView)
    else { return }

    // Leave focus in the overlay alone if it has already claimed first responder.
    window.makeFirstResponder(nil)
  }
}

#endif
