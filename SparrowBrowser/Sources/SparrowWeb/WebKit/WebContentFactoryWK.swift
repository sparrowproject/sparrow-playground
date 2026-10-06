#if os(macOS)
import AppKit
import WebKit

final class WebContentFactoryWK: WebContentFactory {
  init(dependencies: WebContentFactoryDependencies, partition: WebContentStoragePartition) {
    self.dependencies = dependencies
    self.partition = partition
  }

  func createWebContent(initializationParams: WebContentInitializationParams?) -> WebContent {
    WebContentWK(
      dependencies: dependencies,
      configuration: configuration,
      initializationParams: initializationParams,
    )
  }

  private let dependencies: WebContentFactoryDependencies
  private let partition: WebContentStoragePartition

  private lazy var configuration: WKWebViewConfiguration = {
    let configuration = WKWebViewConfiguration()
    if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari"),
      let safariBundle = Bundle(url: safariURL),
      let safariVersion = safariBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    {
      // Safari's compatibility token is frozen; its marketing version comes from the installed app.
      configuration.applicationNameForUserAgent = "Version/\(safariVersion) Safari/605.1.15"
    }
    configuration.preferences.isElementFullscreenEnabled = true

    switch partition.kind {
    case .persistent:
      configuration.websiteDataStore = .init(forIdentifier: partition.identifier)
    case .incognito:
      configuration.websiteDataStore = .nonPersistent()
    }

    return configuration
  }()
}

#endif
