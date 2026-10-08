import Foundation
import Observation
import SparrowWeb
import Tagged

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

extension DownloadModel: Identifiable {}

extension DownloadModel {
  public var isPending: Bool {
    switch webDownloadModel?.status {
    case .starting, .downloading:
      true
    case .completed, .failed, .none:
      false
    }
  }

  public var fileLocation: URL? {
    webDownloadModel?.fileLocation
  }

  public var size: Int64 {
    webDownloadModel?.bytesReceived ?? 0
  }

  public var estimatedTimeRemaining: TimeInterval? {
    // TODO: Implement me!
  }
}