import Foundation
import Observation

@Observable
@MainActor
public final class WebDownloadModel {
  public var sourceURL: URL? // This may change due to redirects.
  public var status: WebDownloadStatus = .starting

  public var fileLocation: URL?

  public var bytesReceived: Int64 = 0
  public var totalBytesToReceive: Int64?

  init() {}
}

extension WebDownloadModel {
  public convenience init(
    sourceURL: URL?,
    status: WebDownloadStatus,
    fileLocation: URL?,
    bytesReceived: Int64,
    totalBytesToReceive: Int64?
  ) {
    self.init()
    self.sourceURL = sourceURL
    self.status = status
    self.fileLocation = fileLocation
    self.bytesReceived = bytesReceived
    self.totalBytesToReceive = totalBytesToReceive
  }
}

public enum WebDownloadStatus: Sendable, Codable {
  case starting
  case downloading
  case completed
  case cancelled
  case failed
}