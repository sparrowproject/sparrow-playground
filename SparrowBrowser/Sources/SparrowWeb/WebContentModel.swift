import Observation
import Foundation
import SparrowUIFoundation

@MainActor
@Observable
public final class WebContentModel {
  public init(
    url: URL?,
    title: String?,
    faviconURL: URL?,
    interactionState: Data?,
  ) {
    self.url = url
    self.title = title
    self.faviconURL = faviconURL
    self.interactionState = interactionState
  }

  public internal(set) var url: URL?
  public internal(set) var title: String?
  public internal(set) var loadingProgress: Double?
  public internal(set) var canGoBack = false
  public internal(set) var canGoForward = false
  public internal(set) var faviconURL: URL?
  public internal(set) var interactionState: Data?

  init() {}
}

extension WebContentModel {
  public var isLoading: Bool { loadingProgress != nil }
}