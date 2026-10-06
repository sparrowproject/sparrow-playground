import Foundation
import SparrowTabs

struct TabData: Codable, Sendable, Equatable {
  let id: TabID
  let url: URL?
  let title: String?
  let faviconURL: URL?
  let interactionState: Data?
}