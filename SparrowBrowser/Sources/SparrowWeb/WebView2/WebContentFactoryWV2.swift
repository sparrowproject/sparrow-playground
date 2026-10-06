#if os(Windows)
import CWinRT
import Foundation
@_spi(WinRTInternal) @preconcurrency import WebView2Core
@preconcurrency import WindowsFoundation
import WinSDK

@MainActor
final class WebContentFactoryWV2: WebContentFactory {
  init(dependencies: WebContentFactoryDependencies, partition: WebContentStoragePartition) {
    self.dependencies = dependencies
    self.partition = partition
  }

  func createWebContent(initializationParams: WebContentInitializationParams?) -> WebContent {
    WebContentWV2(dependencies: dependencies, initializationParams: initializationParams) { [weak self] in
      await self?.configuration()
    }
  }

  private let dependencies: WebContentFactoryDependencies
  private let partition: WebContentStoragePartition
  private var cachedConfiguration: WebContentWV2.Configuration?

  private func configuration() async -> WebContentWV2.Configuration? {
    if let cachedConfiguration {
      return cachedConfiguration
    }

    let userDataDirectory = dependencies.storagePaths.userDataDirectory

    do {
      let environment = try await createWebView2EnvironmentWithOptions(
        "",
        userDataDirectory.path,
        nil
      ).get()!

      let options = try environment.createCoreWebView2ControllerOptions()!
      options.profileName = partition.identifier.uuidString
      options.isInPrivateModeEnabled = partition.kind == .incognito

      let configuration = WebContentWV2.Configuration(
        environment: environment,
        options: options,
      )

      cachedConfiguration = configuration
      return configuration
    } catch {
      print(">>> failed to create WebView2 configuration: \(error)")
      return nil
    }
  }

  private func createWebView2EnvironmentWithOptions(
    _ browserExecutableFolder: String,
    _ userDataFolder: String,
    _ options: CoreWebView2EnvironmentOptions?
  ) throws -> AnyIAsyncOperation<CoreWebView2Environment?>! {
    let statics: __ABI_Microsoft_Web_WebView2_Core.ICoreWebView2EnvironmentStatics =
      try DllGetActivationFactory(
        "Microsoft.Web.WebView2.Core.dll",
        "Microsoft.Web.WebView2.Core.CoreWebView2Environment"
      )

    return try statics.CreateWithOptionsAsync(
      browserExecutableFolder,
      userDataFolder,
      options
    )
  }

  private static var userDataDirectory: URL {
    // TODO: Figure out how to dependency inject this path. This module can't depend on SparrowStorage.

    let appSupportURL = try! FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )

    let identifier = Bundle.main.bundleIdentifier ?? "SparrowBrowser"
    return appSupportURL
      .appendingPathComponent(identifier, isDirectory: true)
  }
}

private func DllGetActivationFactory<Factory: WindowsFoundation.IInspectable>(
  _ dllName: String,
  _ activatableClassId: StaticString
) throws -> Factory {
  typealias DllGetActivationFactoryFunction = @convention(c) (
    HSTRING?,
    UnsafeMutablePointer<UnsafeMutableRawPointer?>?
  ) -> HRESULT

  let module = dllName.withCString(encodedAs: UTF16.self, LoadLibraryW)
  guard let module else {
    throw WindowsFoundation.Error(hr: E_FAIL)
  }

  guard let procedure = GetProcAddress(module, "DllGetActivationFactory") else {
    throw WindowsFoundation.Error(hr: E_FAIL)
  }

  let getActivationFactory = unsafeBitCast(
    procedure,
    to: DllGetActivationFactoryFunction.self
  )

  let (factory) = try ComPtrs.initialize(to: WindowsFoundation.C_IInspectable.self) { factoryAbi in
    try activatableClassId.withHStringRef { activatableClassIdHStr in
      try CHECKED(getActivationFactory(activatableClassIdHStr, &factoryAbi))
    }
  }

  return try factory!.queryInterface() as Factory
}

#endif
