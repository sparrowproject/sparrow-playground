#if os(Windows)
import Foundation
import SparrowUIFoundation
import UWP
@preconcurrency import WebView2Core
@preconcurrency import WindowsFoundation
import WinSDK
import WinUI

final class WebContentWV2: NSObject, WebContent {
  struct Configuration {
    let environment: CoreWebView2Environment
    let options: CoreWebView2ControllerOptions
  }

  typealias Dependencies = WebHistoryProviding
  typealias ConfigurationProvider = @MainActor () async -> Configuration?

  init(
    dependencies: Dependencies,
    initializationParams: WebContentInitializationParams?,
    configurationProvider: @escaping ConfigurationProvider,
  ) {
    self.dependencies = dependencies
    self.configurationProvider = configurationProvider
    super.init()

    webView.coreWebView2Initialized.addHandler { [weak self] _, _ in
      self?.handleWebViewInitialized()
    }

    initializeWebView()

    switch initializationParams {
    case .url(let url):
      load(url: url)
    case .interactionState, .none:
      // TODO: Implement support for interaction state.
      break
    }
  }

  let webView = WebView2()
  var coreWebView: CoreWebView2?
  let model = WebContentModel()
  var action: ((WebContentAction) -> Void)?

  var backForwardList: any WebContentBackForwardList {
    _backForwardList.ensureUpToDate()
    return _backForwardList
  }

  func load(url: URL) {
    guard let coreWebView else {
      pendingURL = url
      return
    }

    try! coreWebView.navigate(url.absoluteString)
  }

  func goBack() {
    try! coreWebView?.goBack()
  }

  func goForward() {
    try! coreWebView?.goForward()
  }

  func goTo(_ item: any WebContentBackForwardListItem) {
    let entryID = (item as! BackForwardList.Item).id

    let parameters = """
    {
      "entryId": \(entryID)
    }
    """

    Task<Void, Never> {
      _ = try? await coreWebView?.callDevToolsProtocolMethodAsync(
        "Page.navigateToHistoryEntry",
        parameters
      ).value
    }
  }

  func reload() {
    try! coreWebView?.reload()
  }

  func stop() {
    try! coreWebView?.stop()
  }

  private enum NavigationState: Equatable {
    case starting
    case domContentLoaded
    case contentLoading
  }

  private let dependencies: Dependencies
  private let configurationProvider: ConfigurationProvider
  private var initializationTask: Task<Void, Never>?
  private var _backForwardList = BackForwardList()
  private var backForwardListTask: Task<Void, Never>?
  private var needsBackForwardListUpdate = false
  private var pendingURL: URL?

  private var navigationIds = [UInt64: NavigationState]() {
    didSet {
      guard navigationIds != oldValue else { return }

      // Use an estimate here for overall loading progress. Assumes that Navigation ID
      // values are assigned using a monotonically increasing counter.
      // TODO: Consider observing the total number of outstanding network requests.
      model.loadingProgress = navigationIds.isEmpty ? nil : {
        switch navigationIds.max(by: { $0.key < $1.key })?.value {
        case .starting:
          0.05
        case .contentLoading:
          0.1
        case .domContentLoaded:
          0.2
        case .none:
          0
        }
      }()
    }
  }

  private func handleWebViewInitialized() {
    let coreWebView = webView.coreWebView2!
    self.coreWebView = coreWebView

    coreWebView.sourceChanged.addHandler { [weak self] _, args in
      guard let self else { return }
      model.url = .init(string: coreWebView.source)

      if !args!.isNewDocument, let faviconURL = model.faviconURL, let pageURL = model.url {
        dependencies.webHistory.storeFaviconURL(
          faviconURL,
          forPageURL: pageURL,
          withColorScheme: .from(webView.actualTheme),
        )
      }
    }

    coreWebView.documentTitleChanged.addHandler { [weak self] _, _ in
      guard let self else { return }
      model.title = coreWebView.documentTitle
    }

    coreWebView.historyChanged.addHandler { [weak self] _, _ in
      guard let self else { return }
      model.canGoBack = coreWebView.canGoBack
      model.canGoForward = coreWebView.canGoForward
      updateBackForwardList()
    }

    coreWebView.navigationStarting.addHandler { [weak self] _, args in
      guard let self else { return }
      navigationIds[args!.navigationId] = .starting
    }

    coreWebView.contentLoading.addHandler { [weak self] _, args in
      guard let self else { return }
      navigationIds[args!.navigationId] = .contentLoading
    }

    coreWebView.domContentLoaded.addHandler { [weak self] _, args in
      guard let self else { return }
      navigationIds[args!.navigationId] = .domContentLoaded
    }

    coreWebView.navigationCompleted.addHandler { [weak self] _, args in
      guard let self else { return }
      navigationIds.removeValue(forKey: args!.navigationId)
    }

    coreWebView.faviconChanged.addHandler { [weak self] _, _ in
      guard let self else { return }
      // print(">>> faviconChanged, uri: \(coreWebView.faviconUri)")
      updateFavicon()
    }

    coreWebView.newWindowRequested.addHandler { [weak self] _, args in
      self?.handleNewWindowRequested(args: args!)
    }

    coreWebView.downloadStarting.addHandler { [weak self] _, args in
      self?.handleDownloadStarting(args: args!)
    }

    if let pendingURL {
      self.pendingURL = nil
      load(url: pendingURL)
    }
  }

  private func initializeWebView() {
    initializationTask = .init { @MainActor in
      defer { initializationTask = nil }

      guard let configuration = await configurationProvider() else {
        print(">>> returning early due to nil configuration!")
        return
      }

      print(">>> calling ensureCoreWebView2Async ...")

      do {
        try await webView.ensureCoreWebView2Async(configuration.environment, configuration.options).get()
      } catch {
        print(">>> failed to initialize WebView2: \(error)")
      }
    }
  }

  private func updateBackForwardList() {
    if backForwardListTask != nil {
      needsBackForwardListUpdate = true
      return
    }
    backForwardListTask = .init {
      needsBackForwardListUpdate = false

      let json = try! await coreWebView?.callDevToolsProtocolMethodAsync(
        "Page.getNavigationHistory",
        "{}"
      ).value

      _backForwardList.pendingJSON = json
      backForwardListTask = nil

      // Kick off another update if needed.
      if needsBackForwardListUpdate {
        updateBackForwardList()
      }
    }
  }

  private func updateFavicon() {
    Task<Void, Never> {
      guard let coreWebView, let pageURL = URL(string: coreWebView.source) else { return }

      guard let faviconURL = URL(string: coreWebView.faviconUri) else {
        print(">>> got a malformed faviconUri that could not be parsed: \(coreWebView.faviconUri)")
        return
      }

      // Avoid redundant work. Assume the data for a given favicon URL is idempotent.
      if await dependencies.webHistory.queryImage(forFaviconURL: faviconURL) == nil {
        let stream = try! await coreWebView.getFaviconAsync(.png).value!
        print(">>> got stream for favicon data: \(stream), of size: \(stream.size), w/ faviconURL: \(faviconURL)")

        dependencies.webHistory.storeImage(
          CachingImageProvider(source: ImageFromStreamProvider(stream: stream)),
          forFaviconURL: faviconURL,
        )
      }

      dependencies.webHistory.storeFaviconURL(
        faviconURL,
        forPageURL: pageURL,
        withColorScheme: .from(webView.actualTheme),
      )

      model.faviconURL = faviconURL
    }
  }

  private func handleNewWindowRequested(args: CoreWebView2NewWindowRequestedEventArgs) {
    print(">>> newWindowRequested")

    // Always mark as handled even if we return early since we don't want the default
    // behavior of the framework opening its own top-level window.
    args.handled = true

    guard let action else { return }

    let webContent = WebContentWV2(
      dependencies: dependencies,
      initializationParams: nil,
      configurationProvider: configurationProvider,
    )

    let deferral = try! args.getDeferral()!

    Task<Void, Never> { @MainActor in
      await webContent.initializationTask?.value

      guard let coreWebView = webContent.coreWebView else {
        print(">>> failed to initialize newly opened webcontent")
        try! deferral.close()
        return
      }

      args.newWindow = coreWebView
      print(">>> newly opened webcontent is initialized!")
      try! deferral.complete()
    }

    action(.createdNew(webContent))
  }

  private func handleDownloadStarting(args: CoreWebView2DownloadStartingEventArgs) {
    print(">>> downloadStarting!")
    args.handled = true
    action?(.downloadStarting(WebDownloadWV2(download: args.downloadOperation)))
  }
}

private final class BackForwardList: WebContentBackForwardList {
  struct Item: WebContentBackForwardListItem {
    let id: Int
    let url: URL
    let title: String?
  }

  var pendingJSON: String?

  private(set) var currentItem: Item?
  private(set) var backList = [Item]()
  private(set) var forwardList = [Item]()

  func ensureUpToDate() {
    guard let pendingJSON else { return }

    let data = Data(pendingJSON.utf8)
    let history = try? JSONDecoder().decode(
      NavigationHistory.self,
      from: data
    )

    guard let history else {
      print(">>> JSON decoding error updating back/forward list")
      return
    }

    currentItem = nil
    backList = []
    forwardList = []

    guard history.entries.count > 0 else { return }

    func makeItem(from entry: NavigationEntry) -> Item? {
      URL(string: entry.url).flatMap {
        .init(id: entry.id, url: $0, title: entry.title)
      }
    }

    for i in 0..<history.currentIndex {
      if let item = makeItem(from: history.entries[i]) {
        backList.append(item)
      }
    }

    if let item = makeItem(from: history.entries[history.currentIndex]) {
      currentItem = item
    }

    for i in history.currentIndex+1..<history.entries.count {
      if let item = makeItem(from: history.entries[i]) {
        forwardList.append(item)
      }
    }
  }
}

private struct NavigationHistory: Decodable {
  let currentIndex: Int
  let entries: [NavigationEntry]
}

private struct NavigationEntry: Decodable {
  let id: Int
  let url: String
  let userTypedURL: String
  let title: String
  let transitionType: String
}

#endif
