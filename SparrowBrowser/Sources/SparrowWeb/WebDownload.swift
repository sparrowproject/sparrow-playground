import Foundation

@MainActor
public protocol WebDownload {
  var model: WebDownloadModel { get }

  func cancel()
}