#if os(macOS)
import WebKit

final class WebDownloadWK: NSObject, WebDownload {
  init(download: WKDownload) {
    self.download = download
    super.init()

    download.delegate = self

    setUpObservers()
  }

  let model = WebDownloadModel()

  func cancel() {
    guard model.status != .completed else { return }

    download.cancel()

    model.status = .failed
  }

  private let download: WKDownload
  private var destinationDecisionCompletion: (@MainActor @Sendable (URL?) -> Void)?
  private var completedObservation: NSKeyValueObservation?
  private var totalObservation: NSKeyValueObservation?

  private func setUpObservers() {
    let progress = download.progress

    completedObservation = progress.observe(
      \.completedUnitCount,
      options: [.initial, .new]
    ) { [weak self] progress, _ in
      guard let self else { return }
      MainActor.assumeIsolated {
        model.bytesReceived = progress.completedUnitCount
      }
    }

    totalObservation = progress.observe(
      \.totalUnitCount,
      options: [.initial, .new]
    ) { [weak self] progress, _ in
      guard let self else { return }
      MainActor.assumeIsolated {
        model.totalBytesToReceive = progress.totalUnitCount
      }
    }
  }
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
