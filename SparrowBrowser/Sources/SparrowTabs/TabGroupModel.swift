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
  public internal(set) var tabIDs = OrderedSet<TabID>() {
    didSet {
      updateMiniGroup()
    }
  }
  public internal(set) var selectedTabModel = Handle<TabModel>(.invalid)

  /// The first N tabIDs are treated as pinned.
  public internal(set) var pinnedCount: Int = 0

  /// Not persisted. This represents a group of tabs opened from the first tab.
  /// This may not be a contiguous run of tabs as the first may be a pinned tab.
  public internal(set) var miniGroup = OrderedSet<TabID>()
}

extension TabGroupModel {
  public static let invalid = TabGroupModel(id: .invalid)

  public var nilIfInvalid: Self? { id == .invalid ? nil : self }
}

extension TabGroupModel: Identifiable {}

extension TabGroupModel {
  func extendMiniGroup(from openerTabID: TabID, adding tabID: TabID) {
    if miniGroup.first == openerTabID {
      miniGroup.append(tabID)
    } else {
      miniGroup = [openerTabID, tabID]
    }
  }

  private func updateMiniGroup() {
    for tabID in miniGroup {
      if tabIDs.contains(tabID) {
        continue
      }
      if tabID == miniGroup.first {
        miniGroup = []
        break
      }
      miniGroup.remove(tabID)
    }
    if miniGroup.count == 1 {
      miniGroup = []
    }
  }
}