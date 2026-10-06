import Foundation
import Observation
import SparrowUIFoundation
import SparrowWeb
import Tagged

@Observable @MainActor
public final class TabModel {
  init(id: TabID, groupID: TabGroupID) {
    self.id = id
    self.groupID = groupID
  }

  public let id: TabID
  public internal(set) var groupID: TabGroupID
  public internal(set) var isSelected = false
  public internal(set) var webContentModel: WebContentModel?
}

extension TabModel {
  public var url: URL? {
    webContentModel?.url
  }

  public var title: String? {
    webContentModel?.title
  }

  public var isLoading: Bool {
    webContentModel?.isLoading ?? false
  }

  public var loadingProgress: Double? {
    webContentModel?.loadingProgress
  }

  public var canGoBack: Bool {
    webContentModel?.canGoBack ?? false
  }

  public var canGoForward: Bool {
    webContentModel?.canGoForward ?? false
  }

  public var faviconURL: URL? {
    webContentModel?.faviconURL
  }

  public var favicon: ImageSource? {
    guard let faviconURL = webContentModel?.faviconURL else { return nil }
    return .favicon(url: faviconURL)
  }

  public var interactionState: Data? {
    webContentModel?.interactionState
  }
}

extension TabModel {
  public static let invalid = TabModel(id: .invalid, groupID: .invalid)
}

extension TabModel: Identifiable {}