#if os(Windows)
import Foundation
import WebView2Core

final class WebDownloadWV2: WebDownload {
  init(download: CoreWebView2DownloadOperation) {
    self.download = download

    model.sourceURL = URL(string: download.uri)
    model.fileLocation = URL(fileURLWithPath: download.resultFilePath)

    setUpObservers()
  }

  let model = WebDownloadModel()

  func cancel() {
    guard model.status != .completed else { return }

    try! download.cancel()

    model.status = .cancelled
  }

  private let download: CoreWebView2DownloadOperation
  
  private func setUpObservers() {
    download.stateChanged.addHandler { [weak self] _, _ in
      guard let self else { return }
      switch download.state {
      case .inProgress:
        model.status = .downloading
      case .interrupted:
        switch download.interruptReason {
        case .userCanceled, .userShutdown:
          model.status = .cancelled
        default:
          model.status = .failed
        }
      case .completed:
        model.status = .completed
      default:
        print(">>> unknown download state: \(download.state)")
      }
    }

    download.bytesReceivedChanged.addHandler { [weak self] _, _ in
      guard let self else { return }
      model.bytesReceived = download.bytesReceived
      model.totalBytesToReceive = (download.totalBytesToReceive < 0) ? nil : download.totalBytesToReceive
    }
  }
}

#endif