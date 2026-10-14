import SparrowUI
import SparrowUICore

// This representable serves to provide a native UI surface above other native UI components
// that make up the browser window (e.g., the native web view).

#if os(macOS)
import AppKit

struct BrowserWindowOverlayViewRepresentable: NSViewRepresentable {
  typealias NSViewType = NSHostingView<BrowserWindowOverlayView>

  let viewModel: BrowserWindowOverlayViewModel
  let action: (BrowserWindowOverlayView.Action) -> Void

  func makeNSView(context: CoreViewContext, associatedView _: CoreView) -> NSViewType {
    let view = NSHostingView(
      content: BrowserWindowOverlayView(viewModel: viewModel, action: action)
    )

    context.scheduler.onChange(
      of: { viewModel.needsHitTesting },
      perform: { [weak view] in view?.isUserInteractionEnabled = $0 },
      cancelWhen: { [weak view] in view == nil },
    )

    return view
  }

  static func tearDownNSView(_ view: NSViewType) {
    view.tearDown()
  }
}

#elseif os(Windows)
import WinUI

struct BrowserWindowOverlayViewRepresentable: WinUIElementRepresentable {
  typealias UIElementType = WinUIHostingView<BrowserWindowOverlayView>

  let viewModel: BrowserWindowOverlayViewModel
  let action: (BrowserWindowOverlayView.Action) -> Void

  func makeUIElement(context: CoreViewContext, associatedView _: CoreView) -> UIElementType {
    let view = WinUIHostingView(
      content: BrowserWindowOverlayView(viewModel: viewModel, action: action)
    )

    context.scheduler.onChange(
      of: { viewModel.needsHitTesting },
      perform: { [weak view] in view?.isHitTestVisible = $0 },
      cancelWhen: { [weak view] in view == nil },
    )

    return view
  }

  static func tearDownUIElement(_ element: UIElementType) {
    element.tearDown()
  }
}

#endif