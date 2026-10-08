import Foundation
import SparrowDownloads
import SparrowWeb

struct DownloadInfo: Codable, Sendable, Equatable {
  let id: DownloadID
  let creationTime: Date

  var sourceURL: URL?
  var status: WebDownloadStatus?
  var fileLocation: URL?
  var bytesReceived: Int64?
  var totalBytesToReceive: Int64?
}

extension DownloadInfo {
  @MainActor
  static func from(_ model: DownloadModel) -> Self {
    .init(
      id: model.id,
      creationTime: model.creationTime,
      sourceURL: model.webDownloadModel?.sourceURL,
      status: model.webDownloadModel?.status,
      fileLocation: model.webDownloadModel?.fileLocation,
      bytesReceived: model.webDownloadModel?.bytesReceived,
      totalBytesToReceive: model.webDownloadModel?.totalBytesToReceive,
    )
  }

  @MainActor
  func makeDownloadModel() -> DownloadModel {
    // When restoring what appears to be an in-progress download, map to cancelled to
    // indicate that it must have been from an interrupted browsing session.
    let status: WebDownloadStatus =
      switch status {
      case .starting, .downloading, .cancelled:
        .cancelled
      case .failed, .none:
        .failed
      case .completed:
        .completed
      }
    return .init(
      id: id,
      creationTime: creationTime,
      webDownloadModel: .init(
        sourceURL: sourceURL,
        status: status,
        fileLocation: fileLocation,
        bytesReceived: bytesReceived ?? 0,
        totalBytesToReceive: totalBytesToReceive,
      ))
  }
}