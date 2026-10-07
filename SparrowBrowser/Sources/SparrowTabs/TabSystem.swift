import SparrowToolbelt
import SparrowWeb

@MainActor
public protocol TabSystem: AnyObject {
  var model: TabSystemModel { get }
  var action: ((TabSystemAction) -> Void)? { get set }

  func initialize(configure: (TabSystemInitializer) async -> Void) async

  @discardableResult
  func load(_ navigation: TabNavigation, inTab: TabID) -> LiveTab
  @discardableResult
  func load(_ navigation: TabNavigation, inGroup: TabGroupID, atIndex: Int?) -> LiveTab

  // TODO: think about the lifecycle of a tab and group...

  func model(forTab tabID: TabID) -> TabModel
  func model(forGroup groupID: TabGroupID) -> TabGroupModel

  func policy(forGroup groupID: TabGroupID) -> TabGroupPolicy

  func liveTab(forTab tabModel: TabModel, createIfNeeded: Bool) -> LiveTab?
  func unloadLiveTabs(forGroup groupID: TabGroupID)

  func remove(tab tabID: TabID)
  func remove(group groupID: TabGroupID)

  func select(tab tabID: TabID)

  func move(tab tabID: TabID, toPositionOf otherTabID: TabID)
}

public protocol TabSystemProviding {
  @MainActor
  var tabSystem: TabSystem { get }
}

public typealias TabSystemDependencies
  = LiveTabDependencies

@MainActor
public enum TabSystemAction {
  case newTabRequested(byTab: TabID, completion: (TabSystemNewTabPolicy) -> Void)
  case startDownload(WebDownload, fromTab: TabID)
}

@MainActor
public enum TabSystemNewTabPolicy {
  case cancel
  case `continue`
}

extension Factory where Interface == TabSystem {
  public static func makeDefaultInstance(dependencies: TabSystemDependencies) -> TabSystem {
    DefaultTabSystem(dependencies: dependencies)
  }
}

final class DefaultTabSystem: TabSystem {
  init(dependencies: TabSystemDependencies) {
    let model = TabSystemModel()

    self.dependencies = dependencies
    self.model = model

    liveTabsManager = .init(dependencies: dependencies, model: model)
    liveTabsManager.action = { [weak self] in
      self?.handleLiveTabsManagerAction($0)
    }
  }

  private(set) var model: TabSystemModel
  var action: ((TabSystemAction) -> Void)?

  func initialize(configure: (TabSystemInitializer) async -> Void) async {
    let initializer = DefaultTabSystemInitializer(model: model)
    await configure(initializer)
    guard !Task.isCancelled else { return }
    initializer.commit()
  }

  func load(_ navigation: TabNavigation, inTab targetTabID: TabID) -> LiveTab {
    print(">>> load in tab")

    let tabModel = model(forTab: targetTabID)
    // tabModel.url = navigation.url

    let liveTab = liveTabsManager.getOrCreate(forModel: tabModel)!
    liveTab.load(navigation)
    return liveTab
  }

  func load(_ navigation: TabNavigation, inGroup targetGroupID: TabGroupID, atIndex index: Int?) -> LiveTab {
    let tabID = TabID()
    let tabModel = makeTabModel(tabID: tabID, groupID: targetGroupID)
    // tabModel.url = navigation.url

    let groupModel = model(forGroup: targetGroupID)

    let policy = policy(forGroup: targetGroupID)
    let index = index ?? policy.decideInsertionIndexForNewTab(inGroup: groupModel)

    groupModel.tabIDs.insert(tabID, at: index)

    let liveTab = liveTabsManager.getOrCreate(forModel: tabModel)!
    liveTab.load(navigation)

    // Select this newly created tab.
    select(tab: tabID)

    return liveTab
  }

  func model(forTab tabID: TabID) -> TabModel {
    guard tabID != .invalid else { return .invalid }

    // If a TabID exists, it should already have a known model.
    return model.tabs[tabID] ?? {
      assertionFailure("TabID without a backing TabModel, tabID: \(tabID)!")
      return .invalid
    }()
  }

  func model(forGroup groupID: TabGroupID) -> TabGroupModel {
    guard groupID != .invalid else { return .invalid }

    // Tab groups are lazily created by this method.
    if let groupModel = model.groups[groupID] {
      return groupModel
    }
    let groupModel = TabGroupModel(id: groupID)
    model.groups[groupID] = groupModel
    return groupModel
  }

  func policy(forGroup groupID: TabGroupID) -> TabGroupPolicy {
    if let policy = policies[groupID] {
      return policy
    }
    let policy = DefaultTabGroupPolicy() // TODO: Consider making this configurable.
    policies[groupID] = policy
    return policy
  }

  func liveTab(forTab tabModel: TabModel, createIfNeeded: Bool) -> LiveTab? {
    if createIfNeeded {
      liveTabsManager.getOrCreate(forModel: tabModel)
    } else {
      liveTabsManager.get(byID: tabModel.id)
    }
  }

  func unloadLiveTabs(forGroup groupID: TabGroupID) {
    guard let groupModel = model.groups[groupID] else {
      assertionFailure("Unknown TabGroupID!")
      return
    }
    for tabID in groupModel.tabIDs {
      liveTabsManager.remove(byID: tabID)
    }
  }

  func remove(tab tabID: TabID) {
    print(">>> remove tab!")

    guard let tabModel = model.tabs[tabID] else {
      assertionFailure("Unknown TabID!")
      return
    }
    guard let groupModel = model.groups[tabModel.groupID] else {
      assertionFailure("Unknown TabGroupID!")
      return
    }

    if groupModel.selectedTabModel.id == tabID {
      print(">>> Updating the selected tab")

      let policy = policy(forGroup: tabModel.groupID)
      let index = policy.decideNextSelectionIndexAfterRemovalOfSelectedTab(inGroup: groupModel)

      groupModel.selectedTabModel.value = index.flatMap { model.tabs[groupModel.tabIDs[$0]] } ?? .invalid
    }

    groupModel.tabIDs.remove(tabID)
    model.tabs.removeValue(forKey: tabID)

    liveTabsManager.remove(byID: tabID)

    if groupModel.tabIDs.isEmpty {
      model.groups.removeValue(forKey: groupModel.id)
    }
  }

  func remove(group groupID: TabGroupID) {
    print(">>> remove group!")

    guard let groupModel = model.groups[groupID] else {
      // Silently ignore removals of groups that are already removed.
      return
    }

    for tabID in groupModel.tabIDs {
      remove(tab: tabID)
    }
  }

  func select(tab tabID: TabID) {
    guard let tabModel = model.tabs[tabID] else {
      assertionFailure("Unknown TabID!")
      return
    }
    guard let groupModel = model.groups[tabModel.groupID] else {
      assertionFailure("Unknown TabGroupID!")
      return
    }
    let oldModel = groupModel.selectedTabModel.value
    groupModel.selectedTabModel.value = tabModel
    oldModel.isSelected = false
    tabModel.isSelected = true
  }

  func move(tab tabID: TabID, toPositionOf otherTabID: TabID) {
    let tabModel = model(forTab: tabID)
    let targetTabModel = model(forTab: otherTabID)

    guard tabModel.groupID == targetTabModel.groupID else {
      // TODO: Make this possible.
      assertionFailure("Can only move a tab to the position of another tab in the same group!")
      return
    }

    let groupModel = model(forGroup: tabModel.groupID)
    groupModel.tabIDs.move(tabID, toPositionOf: otherTabID)
  }

  private let dependencies: TabSystemDependencies
  private let liveTabsManager: LiveTabsManager
  private var policies: [TabGroupID: TabGroupPolicy] = [:]

  private func makeTabModel(tabID: TabID, groupID: TabGroupID) -> TabModel {
    let tabModel = TabModel(id: tabID, groupID: groupID)
    model.tabs[tabID] = tabModel
    return tabModel
  }

  private func handleLiveTabsManagerAction(_ action: LiveTabsManager.Action) {
    switch action {
    case .createNewTabWithContent(let webContent, let openerTabID):
      self.action?(handleCreateNewTab(withWebContent: webContent, openerTabID: openerTabID))
    case .startDownload(let webDownload, let openerTabID):
      self.action?(.startDownload(webDownload, fromTab: openerTabID))
    }
  }

  private func handleCreateNewTab(withWebContent webContent: WebContent, openerTabID: TabID) -> TabSystemAction {
    .newTabRequested(
      byTab: openerTabID,
      completion: { [weak self] newTabPolicy in
        guard newTabPolicy == .continue, let self else { return }

        let openerTabModel = model(forTab: openerTabID)
        let groupID = openerTabModel.groupID
        let groupModel = model(forGroup: groupID)
        let groupPolicy = policy(forGroup: groupID)

        let index = groupPolicy.decideInsertionIndexForNewlyOpenedTab(
          inGroup: groupModel,
          openerTabID: openerTabID,
        )

        let tabID = TabID()
        let tabModel = makeTabModel(tabID: tabID, groupID: groupID)

        groupModel.tabIDs.insert(tabID, at: index)

        _ = liveTabsManager.create(forModel: tabModel, withWebContent: webContent)!

        // Select this newly created tab.
        // TODO: make this configurable!
        select(tab: tabID)
      }
    )
  }
}