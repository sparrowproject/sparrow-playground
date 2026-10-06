import Foundation

extension TabSystem {
  public func liveTab(forTab tabModel: TabModel) -> LiveTab? {
    liveTab(forTab: tabModel, createIfNeeded: true)
  }

  public func liveTab(forTab tabID: TabID, createIfNeeded: Bool = true) -> LiveTab? {
    liveTab(forTab: model(forTab: tabID), createIfNeeded: createIfNeeded)
  }

  public func groupModel(forTab tabID: TabID) -> TabGroupModel {
    model(forGroup: model(forTab: tabID).groupID)
  }

  public func removeTabs(excludingTab excludedTabID: TabID) {
    let groupModel = groupModel(forTab: excludedTabID)
    guard groupModel.id != .invalid else {
      assertionFailure("Tab not found!")
      return
    }
    for tabID in groupModel.tabIDs {
      if tabID != excludedTabID {
        remove(tab: tabID)
      }
    }
  }

  public func removeTabs(afterTab tabID: TabID) {
    let groupModel = groupModel(forTab: tabID)
    guard groupModel.id != .invalid else {
      assertionFailure("Tab not found!")
      return
    }
    let index = groupModel.tabIDs.firstIndex(of: tabID)!
    let tabIDsToRemove = (index+1..<groupModel.tabIDs.count).map {
      groupModel.tabIDs[$0]
    }
    for tabID in tabIDsToRemove {
      remove(tab: tabID)
    }
  }

  @discardableResult
  public func load(_ navigation: TabNavigation, inGroup groupID: TabGroupID) -> LiveTab {
    load(navigation, inGroup: groupID, atIndex: nil)
  }

  @discardableResult
  public func load(_ navigation: TabNavigation, afterTab tabID: TabID) -> LiveTab {
    let groupModel = groupModel(forTab: tabID)
    let index = groupModel.tabIDs.firstIndex(of: tabID)!
    return load(navigation, inGroup: groupModel.id, atIndex: index + 1)
  }

  @discardableResult
  public func duplicateTab(_ tabID: TabID) -> LiveTab {
    // TODO: Ideally this would also duplicate other state from the `WebContent`.
    // Consider adding a method on `WebContent`` to support duplication.
    let tabModel = model(forTab: tabID)
    return load(.init(url: tabModel.url ?? URL(string: "about:blank")!), afterTab: tabID)
  }

  public func selectNextTab(forGroup groupModel: TabGroupModel) {
    guard let index = groupModel.tabIDs.firstIndex(of: groupModel.selectedTabModel.id) else { return }
    let nextIndex = (index + 1) % groupModel.tabIDs.count
    select(tabAtIndex: nextIndex, inGroup: groupModel)
  }

  public func selectPreviousTab(forGroup groupModel: TabGroupModel) {
    guard let index = groupModel.tabIDs.firstIndex(of: groupModel.selectedTabModel.id) else { return }
    var previousIndex = index - 1
    if previousIndex < 0 {
      if groupModel.tabIDs.count > 0 {
        previousIndex = groupModel.tabIDs.count - 1
      } else {
        previousIndex = 0
      }
    }
    select(tabAtIndex: previousIndex, inGroup: groupModel)
  }

  public func select(tabAtIndex index: Int, inGroup groupModel: TabGroupModel) {
    let tabID = groupModel.tabIDs[index]
    select(tab: tabID)
  }
}
