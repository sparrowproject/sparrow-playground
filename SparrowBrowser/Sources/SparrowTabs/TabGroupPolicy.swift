@MainActor
public protocol TabGroupPolicy: AnyObject {
  var insertionMode: TabInsertionMode { get set }

  func decideInsertionIndexForNewTab(inGroup: TabGroupModel) -> Int
  func decideNextSelectionIndexAfterRemovalOfSelectedTab(inGroup: TabGroupModel) -> Int?
  func decideInsertionIndexForNewlyOpenedTab(inGroup: TabGroupModel, openerTabID: TabID) -> Int
}

final class DefaultTabGroupPolicy: TabGroupPolicy {
  init() {}

  var insertionMode = TabInsertionMode.append

  func decideInsertionIndexForNewTab(inGroup group: TabGroupModel) -> Int {
    switch insertionMode {
    case .prepend:
      0

    case .append:
      group.tabIDs.count
    }
  }

  func decideNextSelectionIndexAfterRemovalOfSelectedTab(inGroup group: TabGroupModel) -> Int? {
    // Implement basic policy of just selected the tab before the currently selected tab.

    guard let index = group.tabIDs.firstIndex(of: group.selectedTabModel.id) else { return nil }

    if index > 0 {
      return index - 1
    }

    if group.tabIDs.count > 1 {
      return index + 1
    }

    return nil
  }

  func decideInsertionIndexForNewlyOpenedTab(inGroup group: TabGroupModel, openerTabID: TabID) -> Int {
    guard let openerIndex = group.tabIDs.firstIndex(of: openerTabID) else {
      preconditionFailure("Opener tab should be part of the given group!")
    }
    return openerIndex + 1
  }
}