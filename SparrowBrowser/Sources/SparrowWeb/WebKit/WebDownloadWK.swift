#if os(macOS)
import WebKit

final class WebDownloadWK: NSObject, WebDownload {
  init(download: WKDownload) {
    self.download = download
    super.init()

    download.delegate = self
  }

  let model = WebDownloadModel()

  func cancel() {
    guard model.status != .completed else { return }

    download.cancel()

    model.status = .failed
  }

  // func startDownloading(to destination: URL) {
  //   assert(model.status == .starting)

  //   if let destinationDecisionCompletion {
  //     destinationDecisionCompletion(destination)
  //     self.destinationDecisionCompletion = nil
  //   }

  //   model.status = .downloading
  //   model.fileLocation = destination
  // }

  private let download: WKDownload
  private var destinationDecisionCompletion: (@MainActor @Sendable (URL?) -> Void)?
}

extension WebDownloadWK: WKDownloadDelegate {
  func download(
    _ download: WKDownload,
    decideDestinationUsing response: URLResponse,
    suggestedFilename: String,
    completionHandler: @escaping @MainActor @Sendable (URL?) -> Void
  ) {
    print(">>> download decideDestinationUsing, suggestedFilename: \(suggestedFilename)")

    let fileLocation: URL
    do {
      fileLocation = try buildFileLocation(using: suggestedFilename)
    } catch {
      completionHandler(nil)
      model.status = .failed
      return
    }

    completionHandler(fileLocation)

    model.status = .downloading
    model.fileLocation = fileLocation
  }

  func downloadDidFinish(_ download: WKDownload) {
    print(">>> downloadDidFinish")
    model.status = .completed
  }

  func download(
    _ download: WKDownload,
    didFailWithError error: any Error,
    resumeData: Data?
  ) {
    print(">>> download didFailWithError: \(error)")
    model.status = .failed
  }
}

// TODO: Call this on a background thread instead!
private func buildFileLocation(using suggestedFilename: String) throws -> URL {
  let fileManager = FileManager.default
  let downloadsURL = try fileManager.url(
    for: .downloadsDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: false
  )

  let originalURL = downloadsURL.appendingPathComponent(suggestedFilename)
  let fileExtension = originalURL.pathExtension
  let basename = originalURL.deletingPathExtension().lastPathComponent
  var result = originalURL
  var suffix = 1

  while fileManager.fileExists(atPath: result.path) {
    result = downloadsURL.appendingPathComponent("\(basename) (\(suffix))")
    if !fileExtension.isEmpty {
      result.appendPathExtension(fileExtension)
    }
    suffix += 1
  }

  return result
}

#endif
