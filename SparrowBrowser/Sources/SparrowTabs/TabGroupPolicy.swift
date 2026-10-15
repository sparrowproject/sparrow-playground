@MainActor
public protocol TabGroupPolicy: AnyObject {
  var insertionMode: TabInsertionMode { get set }

  func decideInsertionIndexForNewTab(inGroup: TabGroupModel) -> Int
  func decideInsertionIndexForNewlyOpenedTab(inGroup: TabGroupModel, openerTabID: TabID) -> Int
  func decideNextSelectedTabAfterRemovalOfSelectedTab(inGroup: TabGroupModel) -> TabID?
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

  func decideInsertionIndexForNewlyOpenedTab(inGroup group: TabGroupModel, openerTabID: TabID) -> Int {
    guard let openerIndex = group.tabIDs.firstIndex(of: openerTabID) else {
      preconditionFailure("Opener tab should be part of the given group!")
    }
    if openerTabID == group.miniGroup.first {
      return openerIndex + group.miniGroup.count
    }
    return openerIndex + 1
  }

  func decideNextSelectedTabAfterRemovalOfSelectedTab(inGroup group: TabGroupModel) -> TabID? {
    let selectedTabID = group.selectedTabModel.id

    guard let index = group.tabIDs.firstIndex(of: selectedTabID) else { return nil }

    let range: Range<Int>
    if group.miniGroup.contains(selectedTabID) {
      // Stay within the group!
      let startIndex = group.tabIDs.firstIndex(of: group.miniGroup.first!)!
      range = startIndex..<(startIndex + group.miniGroup.count)
    } else {
      range = 0..<group.tabIDs.count
    }

    let nextIndex: Int? =
      if index < (range.upperBound - 1) {
        index + 1
      } else if index > range.lowerBound {
        index - 1
      } else {
        nil
      }

    return nextIndex.flatMap { group.tabIDs[$0] }
  }
}