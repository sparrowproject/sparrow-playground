import Foundation
import Observation
import OrderedCollections
import Tagged

@Observable
@MainActor
public final class TabUndoModel {
  public typealias EntryID = Tagged<Entry, UUID>

  @MainActor
  public enum Entry {
    case tab(TabModel, groupID: TabGroupID, tabIDs: OrderedSet<TabID>)
    case group(TabGroupModel)
  }

  public private(set) var entries = OrderedDictionary<EntryID, Entry>() {
    didSet {
      print(">>> undo entries: \(entries.values)")
    }
  }

  init() {}

  @discardableResult
  func push(_ entry: Entry) -> EntryID {
    let id = EntryID()
    entries[id] = entry
    return id
  }
}