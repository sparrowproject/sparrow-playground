import Foundation
import Observation

@Observable
@MainActor
public final class WebDownloadModel {
  public var sourceURL: URL? // This may change due to redirects.
  public var status: WebDownloadStatus = .starting

  /// This starts out `nil` and becomes non-nil when `WebDownload.startDownloading(to:)`
  /// is called. It will also be `nil` if `WebDownload.cancel` is called.
  public var fileLocation: URL?

  public var bytesReceived: Int64 = 0
  public var totalBytesToReceive: Int64?

  init() {}
}

public enum WebDownloadStatus {
  case starting
  case downloading
  case completed
  case cancelled
  case failed
}