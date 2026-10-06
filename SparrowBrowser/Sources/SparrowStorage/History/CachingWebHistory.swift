import Foundation
import SparrowToolbelt
import SparrowUIFoundation
import SparrowWeb

/// Adds bounded query caches to a supplied history implementation.
final class CachingWebHistory: WebHistory {
  init(source: WebHistory, maxCount: Int = 256) {
    self.source = source
    faviconURLs = MRUCache(maxCount: maxCount)
    faviconImages = MRUCache(maxCount: maxCount)
  }

  func storeFaviconURL(_ faviconURL: URL, forPageURL pageURL: URL, withColorScheme colorScheme: ColorScheme) {
    source.storeFaviconURL(faviconURL, forPageURL: pageURL, withColorScheme: colorScheme)
    faviconURLs[.init(pageURL: pageURL, colorScheme: colorScheme)] = Task { faviconURL }
  }

  func queryFaviconURL(forPageURL pageURL: URL, withColorScheme colorScheme: ColorScheme) async -> URL? {
    let key = FaviconURLKey(pageURL: pageURL, colorScheme: colorScheme)
    if let cached = faviconURLs[key] { return await cached.value }
    let task = Task { [source] in
      await source.queryFaviconURL(forPageURL: pageURL, withColorScheme: colorScheme)
    }
    faviconURLs[key] = task
    return await task.value
  }

  func storeImage(_ imageProvider: AnyImageProvider, forFaviconURL faviconURL: URL) {
    let cached = CachingImageProvider(source: imageProvider)
    source.storeImage(cached, forFaviconURL: faviconURL)
    faviconImages[faviconURL] = Task { cached }
  }

  func queryImage(forFaviconURL faviconURL: URL) async -> AnyImageProvider? {
    if let cached = faviconImages[faviconURL] { return await cached.value }
    let task = Task<AnyImageProvider?, Never> { [source] in
      await source.queryImage(forFaviconURL: faviconURL)
    }
    faviconImages[faviconURL] = task
    return await task.value
  }

  private struct FaviconURLKey: Hashable {
    let pageURL: URL
    let colorScheme: ColorScheme
  }

  private let source: WebHistory
  // Cache tasks before awaiting so concurrent requests share the same lookup.
  // Completed tasks also retain nil results, and writes replace tasks without
  // allowing an older lookup to overwrite the replacement when it finishes.
  private var faviconURLs: MRUCache<FaviconURLKey, Task<URL?, Never>>
  private var faviconImages: MRUCache<URL, Task<AnyImageProvider?, Never>>
}

extension CachingWebHistory: StorageComponent {
  public func shutdown() -> Task<Void, Never>? {
    faviconURLs.removeAll()
    faviconImages.removeAll()

    return (source as? StorageComponent)?.shutdown()
  }
}
