import OrderedCollections

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
    // If this opener is already the start of a mini-group, then extend the mini-group.
    if openerTabID == group.miniGroup.first {
      guard let lastIndex = group.miniGroup.last.flatMap({ group.tabIDs.firstIndex(of: $0) }) else {
        preconditionFailure("Last tab of mini group not found in given group!")
      }
      return lastIndex + 1
    }

    guard let openerIndex = group.tabIDs.firstIndex(of: openerTabID) else {
      preconditionFailure("Opener tab should be part of the given group!")
    }

    // If the opener is a pinned tab, then the newly opened tab should be just outside the pinned range.
    if openerIndex < group.pinnedCount {
      return group.pinnedCount
    }

    // Else, just open adjacent to the opener.
    return openerIndex + 1
  }

  func decideNextSelectedTabAfterRemovalOfSelectedTab(inGroup group: TabGroupModel) -> TabID? {
    let selectedTabID = group.selectedTabModel.id

    let considerationSet: OrderedSet<TabID>
    if group.miniGroup.contains(selectedTabID) {
      considerationSet = group.miniGroup // Stay within the mini-group!
    } else {
      considerationSet = group.tabIDs
    }

    let range = 0 ..< considerationSet.count
    guard let index = considerationSet.firstIndex(of: selectedTabID) else {
      preconditionFailure("Selected tab not found in consideration set!")
    }

    let nextIndex: Int? =
      if index < (range.upperBound - 1) {
        index + 1
      } else if index > range.lowerBound {
        index - 1
      } else {
        nil
      }

    return nextIndex.flatMap { considerationSet[$0] }
  }
}