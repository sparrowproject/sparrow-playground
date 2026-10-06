#if os(macOS)
import AppKit
@testable import SparrowStorage
import SparrowToolbelt
import SparrowUIFoundation
import SparrowWeb

@MainActor
func testPersistentWebHistory(_ root: URL) async throws {
  struct Paths: StoragePaths {
    let userDataDirectory: URL
  }
  @MainActor
  struct Dependencies: PersistentWebHistoryDependencies {
    let storagePaths: any StoragePaths
  }
  struct Provider: ImageProvider {
    let image: NSImage
    func getImage() async -> ImageRef? { image }
  }

  let directory = root.appendingPathComponent("history")
  let dependencies = Dependencies(storagePaths: Paths(userDataDirectory: directory))
  let url = URL(string: "https://example.com/favicon.png")!
  var history: WebHistory? = Factory<WebHistory>.makePersistentInstance(dependencies: dependencies)
  let missing = await history!.queryImage(forFaviconURL: url)
  precondition(missing == nil)

  let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
  )!
  for x in 0..<2 {
    for y in 0..<2 {
      bitmap.setColor(NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1), atX: x, y: y)
    }
  }
  let image = NSImage(size: NSSize(width: 2, height: 2))
  image.addRepresentation(bitmap)
  history!.storeImage(Provider(image: image), forFaviconURL: url)

  // storeImage resolves its provider asynchronously before enqueueing the write.
  var provider: AnyImageProvider?
  for _ in 0..<100 {
    provider = await history!.queryImage(forFaviconURL: url)
    if provider != nil { break }
    try await Task.sleep(for: .milliseconds(10))
  }
  let decoded = await provider?.getImage()
  precondition(decoded != nil, "Stored image must round-trip")
  let cached = await provider?.getImage()
  precondition(decoded === cached, "Repeated requests must reuse the decoded image")
  let pixels = NSBitmapImageRep(data: decoded!.tiffRepresentation!)!
  precondition(pixels.pixelsWide == 2 && pixels.pixelsHigh == 2)
  precondition(pixels.colorAt(x: 0, y: 0)!.redComponent > 0.99)
  await (history! as! any StorageComponent).shutdown()?.value
  history = nil

  let store = BlobStore(directory: directory.appendingPathComponent("favicon-images"))
  let bytes = try await store.read(forKey: url.absoluteString)
  precondition(bytes?.prefix(8) == Data([137, 80, 78, 71, 13, 10, 26, 10]), "Persisted format must be PNG")
  let invalidURL = URL(string: "https://example.com/invalid.png")!
  store.write(Data([0, 1, 2]), forKey: invalidURL.absoluteString)
  try store.close()

  history = Factory<WebHistory>.makePersistentInstance(dependencies: dependencies)
  let restored = await history!.queryImage(forFaviconURL: url)
  let restoredImage = await restored?.getImage()
  precondition(restoredImage != nil, "Images must survive reopening history")
  let invalid = await history!.queryImage(forFaviconURL: invalidURL)
  precondition(invalid != nil, "Query must return stored bytes without eagerly decoding")
  let invalidImage = await invalid?.getImage()
  precondition(invalidImage == nil, "Invalid image data must fail gracefully when requested")
  await (history! as! any StorageComponent).shutdown()?.value
  history = nil

  // Exercise persistence directly, without cache hits masking pending writes.
  let concurrent = PersistentWebHistory(dependencies: dependencies)
  let first = SuspendedImageProvider()
  let second = SuspendedImageProvider()
  concurrent.storeImage(first, forFaviconURL: url)
  while first.continuation == nil { await Task.yield() }
  var readFinished = false
  var readStarted = false
  let read = Task {
    readStarted = true
    let result = await concurrent.queryImage(forFaviconURL: url)
    readFinished = true
    return result
  }
  while !readStarted { await Task.yield() }
  precondition(!readFinished, "Reads must wait for pending providers")
  concurrent.storeImage(second, forFaviconURL: url)
  precondition(second.continuation == nil, "Same-key writes must run in call order")
  first.continuation!.resume(returning: image)
  while second.continuation == nil { await Task.yield() }
  precondition(!readFinished, "A read must also wait for writes added while suspended")

  let otherURL = URL(string: "https://example.com/other.png")!
  concurrent.storeImage(Provider(image: image), forFaviconURL: otherURL)
  let other = await concurrent.queryImage(forFaviconURL: otherURL)
  precondition(other != nil, "Different keys must progress independently")

  let replacement = NSImage(size: NSSize(width: 3, height: 3))
  replacement.addRepresentation(NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: 3, pixelsHigh: 3,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
  )!)
  second.continuation!.resume(returning: replacement)
  let latest = await read.value
  let latestImage = await latest?.getImage()
  precondition(latestImage?.size.width == 3, "The last successful write must win")

  // A failed provider must release its write slot and preserve stored bytes.
  concurrent.storeImage(NilImageProvider(), forFaviconURL: url)
  let preserved = await concurrent.queryImage(forFaviconURL: url)
  let preservedImage = await preserved?.getImage()
  precondition(preservedImage?.size.width == 3)

  let pending = SuspendedImageProvider()
  concurrent.storeImage(pending, forFaviconURL: url)
  concurrent.storeImage(Provider(image: replacement), forFaviconURL: url)
  while pending.continuation == nil { await Task.yield() }
  let shutdown = concurrent.shutdown()
  let repeatedShutdown = concurrent.shutdown()
  concurrent.storeImage(Provider(image: image), forFaviconURL: url)
  pending.continuation!.resume(returning: image)
  await shutdown?.value
  await repeatedShutdown?.value
  let closedResult = await concurrent.queryImage(forFaviconURL: url)
  precondition(closedResult == nil)
  let reopened = PersistentWebHistory(dependencies: dependencies)
  let finalProvider = await reopened.queryImage(forFaviconURL: url)
  let finalImage = await finalProvider?.getImage()
  precondition(finalImage?.size.width == 3, "Shutdown must drain every accepted write")
  await reopened.shutdown()?.value
}

@MainActor
private final class SuspendedImageProvider: ImageProvider {
  var continuation: CheckedContinuation<ImageRef?, Never>?
  func getImage() async -> ImageRef? {
    await withCheckedContinuation { continuation = $0 }
  }
}

private struct NilImageProvider: ImageProvider {
  func getImage() async -> ImageRef? { nil }
}
#endif
