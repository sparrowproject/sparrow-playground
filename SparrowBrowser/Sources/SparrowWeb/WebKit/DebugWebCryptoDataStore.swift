#if os(macOS) && DEBUG
import CryptoKit
import ObjectiveC
import WebKit

/// Development-only replacement for WebKit's keychain-backed master key.
/// Installs a delegate on an existing store and persists only its master key.
/// Existing keychain-encrypted WebCrypto data cannot be read with this debug key.
@MainActor
enum DebugWebCryptoDataStore {
  private static var delegateAssociation: UInt8 = 0

  static func installDelegate(on store: WKWebsiteDataStore, partitionIdentifier: UUID) {
    let selector = NSSelectorFromString("set_delegate:")
    precondition(
      store.responds(to: selector),
      "This WebKit version does not support the debug WebCrypto delegate"
    )

    let key: Data
    if store.isPersistent {
      let defaults = UserDefaults.standard
      let name = "DebugWebCryptoMasterKey.\(partitionIdentifier.uuidString)"
      if let storedKey = defaults.data(forKey: name), storedKey.count == 16 {
        key = storedKey
      } else {
        key = makeKey()
        defaults.set(key, forKey: name)
      }
    } else {
      key = makeKey()
    }

    let delegate = DebugWebCryptoDelegate(key: key)
    // WebKit's private delegate is weak. Retain it for the store's lifetime,
    // including web views created for popups that can outlive their factory.
    objc_setAssociatedObject(store, &delegateAssociation, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    store.perform(selector, with: delegate)
  }

  private static func makeKey() -> Data {
    SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }
  }
}

private final class DebugWebCryptoDelegate: NSObject {
  init(key: Data) {
    self.key = key
    super.init()
  }

  private let key: Data

  // _WKWebsiteDataStoreDelegate (macOS 15+). Keep this private API in DEBUG.
  @objc(webCryptoMasterKey:)
  func webCryptoMasterKey(_ completionHandler: @escaping @convention(block) (NSData) -> Void) {
    completionHandler(key as NSData)
  }
}
#endif
