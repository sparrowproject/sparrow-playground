#if os(macOS)
import Combine
import SparrowUIFoundation
import WebKit

final class WebContentWK: NSObject, WebContent {
  typealias Dependencies = WebHistoryProviding

  init(
    dependencies: Dependencies,
    configuration: WKWebViewConfiguration,
    initializationParams: WebContentInitializationParams?,
  ) {
    // TODO: Setup properly.
    self.dependencies = dependencies
    webView = .init(frame: .zero, configuration: configuration)

    super.init()

    webView.allowsMagnification = true
    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.perform(NSSelectorFromString("_setIconLoadingDelegate:"), with: self)

    setUpObservers()

    switch initializationParams {
    case .url(let url):
      print(">>> navigating newly created webview to: \(url)")
      load(url: url)
    case .interactionState(let data):
      print(">>> assigning interactionState to newly created webview!")
      webView.interactionState = data
    case .none:
      break
    }
  }

  let webView: WKWebView
  let model = WebContentModel()
  var action: ((WebContentAction) -> Void)?

  var backForwardList: any WebContentBackForwardList {
    webView.backForwardList
  }

  var isForeground = false {
    didSet {
      updateInteractionState()
    }
  }

  func load(url: URL) {
    // TODO: Handle case of provisional URL during loading.
    webView.load(.init(url: url))
  }

  var inputDisabled = false {
    didSet {
      guard inputDisabled != oldValue else { return }
      let selector = NSSelectorFromString("_setIgnoresMouseMoveEvents:")
      guard webView.responds(to: selector), let implementation = webView.method(for: selector) else {
        return
      }
      // This private setter takes a BOOL, so it cannot be invoked with perform(_:with:).
      typealias Setter = @convention(c) (AnyObject, Selector, Bool) -> Void
      let setter = unsafeBitCast(implementation, to: Setter.self)
      setter(webView, selector, inputDisabled)
    }
  }

  func goBack() {
    webView.goBack()
  }

  func goForward() {
    webView.goForward()
  }

  func goTo(_ item: WebContentBackForwardListItem) {
    webView.go(to: item as! WKBackForwardListItem)
  }

  func reload() {
    webView.reload()
  }

  func stop() {
    webView.stopLoading()
  }

  private var bag = Set<AnyCancellable>()
  private let dependencies: Dependencies

  private func setUpObservers() {
    webView.publisher(for: \.url, options: [.initial, .new])
      .sink { [model, weak self] in
        model.url = $0
        self?.updateInteractionState()
      }
      .store(in: &bag)

    webView.publisher(for: \.title, options: [.initial, .new])
      .sink { [model] in
        model.title = $0
      }
      .store(in: &bag)

    Publishers.CombineLatest(
      webView.publisher(for: \.isLoading, options: [.initial, .new]),
      webView.publisher(for: \.estimatedProgress, options: [.initial, .new]),
    )
    .sink { [model] in
      model.loadingProgress = $0 ? $1 : nil
    }
    .store(in: &bag)

    webView.publisher(for: \.canGoBack, options: [.initial, .new])
      .sink { [model, weak self] in
        model.canGoBack = $0
        self?.updateInteractionState()
      }
      .store(in: &bag)

    webView.publisher(for: \.canGoForward, options: [.initial, .new])
      .sink { [model, weak self] in
        model.canGoForward = $0
        self?.updateInteractionState()
      }
      .store(in: &bag)
  }

  private func updateInteractionState() {
    model.interactionState = webView.interactionState as? Data
  }
}

extension WebContentWK: WKNavigationDelegate {
  func webView(
    _ webView: WKWebView,
    didStartProvisionalNavigation navigation: WKNavigation!
  ) {
    // print(">>> started:", webView.url as Any)
  }

  func webView(
    _ webView: WKWebView,
    didCommit navigation: WKNavigation!
  ) {
    // print(">>> committed:", webView.url as Any)
  }

  func webView(
    _ webView: WKWebView,
    didFinish navigation: WKNavigation!
  ) {
    // print(">>> finished:", webView.url as Any)
    updateInteractionState()
  }

  func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    print(">>> PROVISIONAL ERROR:", error)
  }

  func webView(
      _ webView: WKWebView,
      didFail navigation: WKNavigation!,
      withError error: Error
  ) {
    print(">>> NAVIGATION ERROR:", error)
  }

  func webView(
    _ webView: WKWebView,
    navigationResponse: WKNavigationResponse,
    didBecome download: WKDownload
  ) {
    print(">>> navigation response did become download!")
  }

  func webView(
    _ webView: WKWebView,
    navigationAction: WKNavigationAction,
    didBecome download: WKDownload
  ) {
    print(">>> navigation action did become download!")
  }

  // This private selector is implemented so we can learn when the URL of the
  // page changes without the underlying document changing. This way we can
  // associate the new page URL with the same favicon.
  @objc(_webView:navigation:didSameDocumentNavigation:)
  func _webView(
      _ webView: WKWebView,
      navigation: WKNavigation?,
      didSameDocumentNavigation type: Int
  ) {
    if let pageURL = webView.url, let faviconURL = model.faviconURL {
      dependencies.webHistory.storeFaviconURL(
        faviconURL,
        forPageURL: pageURL,
        withColorScheme: .from(webView.effectiveAppearance),
      )
    }
  }
}

extension WebContentWK: WKUIDelegate {
  func webView(
    _ webView: WKWebView,
    createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction,
    windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    print("New web view requested")
    print("URL:", navigationAction.request.url as Any)
    print("targetFrame:", navigationAction.targetFrame as Any)

    guard let action else { return nil }

    let webContent = WebContentWK(
      dependencies: dependencies,
      configuration: configuration,
      initializationParams: nil,
    )
    action(.createdNew(webContent))
    return webContent.webView
  }
}

// These declarations mirror WebKit's private _WKIconLoadingDelegate protocol.
// Keeping them here avoids depending on private SDK headers while still exposing
// the Objective-C selector WebKit looks up on its delegate.
@objc(_WKIconLoadingDelegate)
@MainActor
private protocol WKIconLoadingDelegate: NSObjectProtocol {
  @objc(webView:shouldLoadIconWithParameters:completionHandler:)
  optional func webView(
    _ webView: WKWebView,
    shouldLoadIconWithParameters parameters: NSObject,
    completionHandler: @escaping (@escaping (Data) -> Void) -> Void
  )
}

extension WebContentWK: WKIconLoadingDelegate {
  func webView(
    _ webView: WKWebView,
    shouldLoadIconWithParameters parameters: NSObject,
    completionHandler: @escaping (@escaping (Data) -> Void) -> Void
  ) {
    guard
      let pageURL = webView.url,
      let faviconURL = parameters.value(forKey: "url") as? URL
    else {
      completionHandler { _ in }
      return
    }

    completionHandler { [weak self] data in
      guard let self else { return }

      Task<Void, Never> {
        // Avoid redundant work. Assume the data for a given favicon URL is idempotent.
        if await dependencies.webHistory.queryImage(forFaviconURL: faviconURL) == nil {
          dependencies.webHistory.storeImage(
            ImageFromDataProvider(data: data),
            forFaviconURL: faviconURL
          )
        }
        dependencies.webHistory.storeFaviconURL(
          faviconURL,
          forPageURL: pageURL,
          withColorScheme: .from(webView.effectiveAppearance),
        )
        model.faviconURL = faviconURL
      }
    }
  }
}

private struct ImageFromDataProvider: ImageProvider {
  let data: Data

  func getImage() async -> ImageRef? {
    .init(data: data)
  }
}

extension WKBackForwardListItem: WebContentBackForwardListItem {}
extension WKBackForwardList: WebContentBackForwardList {}

#endif
