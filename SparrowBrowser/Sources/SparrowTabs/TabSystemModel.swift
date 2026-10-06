import Observation
import Tagged

@Observable @MainActor
public final class TabSystemModel {
  public internal(set) var tabs: [TabID: TabModel] = [:]
  public internal(set) var groups: [TabGroupID: TabGroupModel] = [:]

  var liveTabs = [TabID: LiveTab]() {
    didSet {
      print(">>> liveTabs exist for: \(liveTabs.keys)")
    }
  }
}

extension TabSystemModel {
  public func liveTabs(forGroup groupID: TabGroupID) -> [LiveTab] {
    guard let groupModel = groups[groupID] else {
      return []
    }
    return groupModel.tabIDs.compactMap { liveTabs[$0] }
  }

  public func selectedLiveTab(forGroup groupID: TabGroupID) -> LiveTab? {
    guard let groupModel = groups[groupID] else {
      return nil
    }
    return liveTabs[groupModel.selectedTabModel.id]
  }
}