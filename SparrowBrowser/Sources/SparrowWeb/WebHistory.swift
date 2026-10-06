import Foundation
import SparrowUIFoundation
import SparrowToolbelt

@MainActor
public protocol WebHistory: AnyObject {
  func storeFaviconURL(_: URL, forPageURL: URL, withColorScheme: ColorScheme)
  func queryFaviconURL(forPageURL: URL, withColorScheme: ColorScheme) async -> URL?

  func storeImage(_: AnyImageProvider, forFaviconURL: URL)
  func queryImage(forFaviconURL: URL) async -> AnyImageProvider?
}

public protocol WebHistoryProviding {
  @MainActor
  var webHistory: WebHistory { get }
}

extension Factory where Interface == WebHistory {
  public static func makeInMemoryInstance() -> WebHistory {
    InMemoryWebHistory()
  }
}

/// A simplistic in-memory implementation.
private final class InMemoryWebHistory: WebHistory {
  func storeFaviconURL(_ faviconURL: URL, forPageURL pageURL: URL, withColorScheme colorScheme: ColorScheme) {
    faviconURLs[.init(pageURL: pageURL, colorScheme: colorScheme)] = faviconURL
  }

  func queryFaviconURL(forPageURL pageURL: URL, withColorScheme colorScheme: ColorScheme) async -> URL? {
    // Simulate an async lookup.
    await Task<URL?, Never> {
      faviconURLs[.init(pageURL: pageURL, colorScheme: colorScheme)]
    }.value
  }

  func storeImage(_ imageProvider: AnyImageProvider, forFaviconURL faviconURL: URL) {
    faviconImages[faviconURL] = imageProvider
  }
 
  func queryImage(forFaviconURL faviconURL: URL) async -> AnyImageProvider? {
    // Simulate an async lookup.
    await Task<AnyImageProvider?, Never> {
      faviconImages[faviconURL]
    }.value
  }

  private struct CacheKey: Hashable {
    let pageURL: URL
    let colorScheme: ColorScheme
  }

  private var faviconURLs = [CacheKey: URL]()
  private var faviconImages = [URL: AnyImageProvider]()
}