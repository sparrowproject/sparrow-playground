import Observation
import OrderedCollections
import SparrowToolbelt
import Tagged

@Observable @MainActor
public final class TabGroupModel {
  init(id: TabGroupID) {
    self.id = id
  }

  public let id: TabGroupID
  public internal(set) var tabIDs: OrderedSet<TabID> = []
  public internal(set) var selectedTabModel: Handle<TabModel> = .init(.invalid)

  // Are these the right states?
  // public internal(set) var isPinned = false
  // public internal(set) var isHidden = false
}

extension TabGroupModel {
  public static let invalid = TabGroupModel(id: .invalid)
}

extension TabGroupModel: Identifiable {}