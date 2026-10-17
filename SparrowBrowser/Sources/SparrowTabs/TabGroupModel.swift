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

  /// Not persisted. This represents a group of tabs opened from the first tab.
  public internal(set) var miniGroup = OrderedSet<TabID>()
}

extension TabGroupModel {
  public static let invalid = TabGroupModel(id: .invalid)

  public var nilIfInvalid: Self? { id == .invalid ? nil : self }
}

extension TabGroupModel: Identifiable {}

extension TabGroupModel {
  func extendMiniGroup(from openerTabID: TabID, adding tabID: TabID) {
    let openerIndex = tabIDs.firstIndex(of: openerTabID)!
    let tabIndex = tabIDs.firstIndex(of: tabID)!

    if miniGroup.first == openerTabID {
      miniGroup.insert(tabID, at: tabIndex - openerIndex)
    } else {
      miniGroup = [openerTabID, tabID]
    }

    // Assert that `miniGroup` is a contiguous subset of `tabIDs`:
    for i in 0..<miniGroup.count {
      assert(tabIDs[openerIndex + i] == miniGroup[i])
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