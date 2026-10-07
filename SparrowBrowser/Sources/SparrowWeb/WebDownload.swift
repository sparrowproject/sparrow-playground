import Foundation

@MainActor
public protocol WebDownload {
  var url: URL? { get }
}