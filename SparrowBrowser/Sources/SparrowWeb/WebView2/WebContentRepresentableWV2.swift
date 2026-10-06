#if os(Windows)
import SparrowUI
import SparrowUICore
import WinUI

struct WebContentRepresentable: WinUIElementRepresentable {
  init(viewModel: WebContentViewModel) {
    self.viewModel = viewModel
  }

  func makeUIElement(context: CoreViewContext, associatedView _: CoreView) -> WebViewContainer {
    .init(scheduler: context.scheduler, viewModel: viewModel)
  }

  static func tearDownUIElement(_: WebViewContainer) {}

  let viewModel: WebContentViewModel
}

@MainActor
final class WebViewContainer: Grid {
  init(scheduler: CoreScheduler, viewModel: WebContentViewModel) {
    super.init()

    print(">>> WebViewContainer.init")

    scheduler.onChange(
      of: { viewModel.allWebContent },
      perform: { [weak self] in
        self?.allWebContent = $0
      },
      cancelWhen: { [weak self] in
        self == nil
      }
    )

    scheduler.onChange(
      of: { viewModel.selectedWebContent },
      perform: { [weak self] in
        self?.selectedWebContent = $0
      },
      cancelWhen: { [weak self] in
        self == nil
      }
    )
  }

  private var allWebContent = [WebContent]() {
    didSet {
      // print(">>> allWebContent changed, count: \(allWebContent.count)")

      print(">>> allWebContent changed: \(allWebContent.map { ObjectIdentifier($0.webView.thisPtr) })")

      for webContent in allWebContent {
        if children.index(of: webContent.webView) == nil {
          print(">>> adding webView @ \(ObjectIdentifier(webContent.webView.thisPtr))")
          children.append(webContent.webView)
          webContent.webView.visibility = (webContent === selectedWebContent) ? .visible : .collapsed
        }
      }

      if children.count > allWebContent.count {
        // Find the WebView that is no longer needed and remove it. The trick is that we can't
        // rely on testing object identity since `children` may contain unique wrapper instances.
        // We can rely on `index(of:)` however...

        var indicesToKeep: [Bool] = Array(repeating: false, count: children.count)

        for webContent in allWebContent {
          indicesToKeep[children.index(of: webContent.webView)!] = true
        }

        for (index, keep) in indicesToKeep.enumerated().reversed() {
          if !keep {
            children.removeAt(UInt32(index))
          }
        }
      }

      print(">>> children.count: \(children.count)")
    }
  }

  private var selectedWebContent: WebContent? {
    didSet {
      guard selectedWebContent !== oldValue else { return }

      // print(">>> selectedWebContent: \(selectedWebContent)")

      oldValue?.webView.visibility = .collapsed
      selectedWebContent?.webView.visibility = .visible
    }
  }
}

#endif
