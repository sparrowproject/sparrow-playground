import Foundation
@testable import SparrowStorage
import SparrowToolbelt
import SparrowUIFoundation
import SparrowWeb

@MainActor
private final class HistorySource: WebHistory, StorageComponent {
  var urlQueries = 0
  var imageQueries = 0
  var urlWrites = 0
  var imageWrites = 0
  var stopped = false
  var suspendedURLQuery: CheckedContinuation<URL?, Never>?
  var suspendURLQueries = false

  func storeFaviconURL(_ url: URL, forPageURL: URL, withColorScheme: ColorScheme) {
    urlWrites += 1
  }
  func queryFaviconURL(forPageURL: URL, withColorScheme: ColorScheme) async -> URL? {
    urlQueries += 1
    if suspendURLQueries {
      return await withCheckedContinuation { suspendedURLQuery = $0 }
    }
    return nil
  }
  func storeImage(_ provider: AnyImageProvider, forFaviconURL: URL) {
    imageWrites += 1
  }
  func queryImage(forFaviconURL: URL) async -> AnyImageProvider? {
    imageQueries += 1
    return nil
  }
  func shutdown() -> Task<Void, Never>? {
    stopped = true
    return nil
  }
}

private struct EmptyImageProvider: ImageProvider {
  func getImage() async -> ImageRef? { nil }
}

@MainActor
func testCachingWebHistory() async {
  let source = HistorySource()
  let history = CachingWebHistory(source: source, maxCount: 2)
  let a = URL(string: "https://example.com/a")!
  let b = URL(string: "https://example.com/b")!
  let c = URL(string: "https://example.com/c")!

  _ = await history.queryFaviconURL(forPageURL: a, withColorScheme: .light)
  _ = await history.queryFaviconURL(forPageURL: b, withColorScheme: .light)
  _ = await history.queryFaviconURL(forPageURL: a, withColorScheme: .light)
  precondition(source.urlQueries == 2, "Missing results must be cached")
  _ = await history.queryFaviconURL(forPageURL: c, withColorScheme: .light)
  _ = await history.queryFaviconURL(forPageURL: b, withColorScheme: .light)
  precondition(source.urlQueries == 4, "The least recently used result must be evicted")
  _ = await history.queryFaviconURL(forPageURL: b, withColorScheme: .dark)
  precondition(source.urlQueries == 5, "Color schemes need distinct cache keys")

  _ = await history.queryImage(forFaviconURL: a)
  _ = await history.queryImage(forFaviconURL: b)
  _ = await history.queryImage(forFaviconURL: a)
  precondition(source.imageQueries == 2)
  _ = await history.queryImage(forFaviconURL: c)
  _ = await history.queryImage(forFaviconURL: b)
  precondition(source.imageQueries == 4)
  history.storeImage(EmptyImageProvider(), forFaviconURL: b)
  let provider = await history.queryImage(forFaviconURL: b)
  precondition(provider != nil && source.imageQueries == 4 && source.imageWrites == 1)

  source.suspendURLQueries = true
  let lookup = Task { await history.queryFaviconURL(forPageURL: c, withColorScheme: .dark) }
  while source.suspendedURLQuery == nil { await Task.yield() }
  let concurrent = Task { await history.queryFaviconURL(forPageURL: c, withColorScheme: .dark) }
  await Task.yield()
  precondition(source.urlQueries == 6, "Concurrent queries must share a lookup")
  history.storeFaviconURL(a, forPageURL: c, withColorScheme: .dark)
  source.suspendedURLQuery!.resume(returning: b)
  _ = await lookup.value
  _ = await concurrent.value
  let latest = await history.queryFaviconURL(forPageURL: c, withColorScheme: .dark)
  precondition(latest == a && source.urlWrites == 1, "An old lookup must not overwrite a write")

  await history.shutdown()?.value
  precondition(source.stopped, "Shutdown must reach the underlying implementation")
}
