import Foundation
import Observation
import SparrowWeb

@Observable
@MainActor
public final class DownloadModel {
  public let id: DownloadID
  public let creationTime: Date

  /// An in-progress or complete download will have an associated `WebDownloadModel`.
  public var webDownloadModel: WebDownloadModel?

  init(id: DownloadID) {
    self.id = id
    creationTime = .now
  }
}

extension DownloadModel {
  var isPending: Bool {
    switch webDownloadModel?.status {
    case .starting, .downloading:
      true
    case .completed, .failed, .none:
      false
    }
  }

  var fileLocation: URL? {
    webDownloadModel?.fileLocation
  }

  var size: Int64 {
    webDownloadModel?.bytesReceived ?? 0
  }
}