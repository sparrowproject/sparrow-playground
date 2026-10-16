import SparrowToolbelt
import SparrowUIFoundation
import SparrowWeb

@MainActor
public protocol TabSystem: AnyObject {
  var model: TabSystemModel { get }
  var action: ((TabSystemAction) -> Void)? { get set }

  func initialize(configure: (TabSystemInitializer) async -> Void) async

  @discardableResult
  func load(_ navigation: TabNavigation, inTab: TabID) -> LiveTab
  @discardableResult
  func load(_ navigation: TabNavigation, inGroup: TabGroupID, atIndex: Int?, select: Bool) -> LiveTab

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
  case newTabRequested(byTab: TabID, modifierFlags: Keystroke.ModifierFlags, completion: (TabSystemNewTabPolicy) -> Void)
  case startDownload(WebDownload, fromTab: TabID)
}

@MainActor
public enum TabSystemNewTabPolicy: Equatable {
  case cancel
  case `continue`
  case continueWithGroup(TabGroupID)
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
    let tabModel = model(forTab: targetTabID)

    let liveTab = liveTabsManager.getOrCreate(forModel: tabModel)!
    liveTab.load(navigation)
    return liveTab
  }

  func load(_ navigation: TabNavigation, inGroup targetGroupID: TabGroupID, atIndex index: Int?, select: Bool) -> LiveTab {
    let tabID = TabID()
    let tabModel = makeTabModel(tabID: tabID, groupID: targetGroupID)

    let groupModel = model(forGroup: targetGroupID)

    let policy = policy(forGroup: targetGroupID)
    let index = index ?? policy.decideInsertionIndexForNewTab(inGroup: groupModel)

    groupModel.tabIDs.insert(tabID, at: index)

    let liveTab = liveTabsManager.getOrCreate(forModel: tabModel)!
    liveTab.load(navigation)

    if select {
      self.select(tab: tabID)
    }

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
    guard let tabModel = model.tabs[tabID] else {
      assertionFailure("Unknown TabID!")
      return
    }
    guard let groupModel = model.groups[tabModel.groupID] else {
      assertionFailure("Unknown TabGroupID!")
      return
    }

    if groupModel.selectedTabModel.id == tabID {
      let policy = policy(forGroup: tabModel.groupID)
      let nextTabID = policy.decideNextSelectedTabAfterRemovalOfSelectedTab(inGroup: groupModel)

      groupModel.selectedTabModel.value = nextTabID.flatMap { model.tabs[$0] } ?? .invalid
    }

    groupModel.tabIDs.remove(tabID)
    model.tabs.removeValue(forKey: tabID)

    liveTabsManager.remove(byID: tabID)

    if groupModel.tabIDs.isEmpty {
      model.groups.removeValue(forKey: groupModel.id)
    }
  }

  func remove(group groupID: TabGroupID) {
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
    case .createNewTabWithContent(let webContent, let modifierFlags, let openerTabID):
      self.action?(handleCreateNewTab(
        withWebContent: webContent,
        modifierFlags: modifierFlags,
        openerTabID: openerTabID,
      ))
    case .startDownload(let webDownload, let openerTabID):
      self.action?(.startDownload(webDownload, fromTab: openerTabID))
    }
  }

  private func handleCreateNewTab(
    withWebContent webContent: WebContent,
    modifierFlags: Keystroke.ModifierFlags,
    openerTabID: TabID
  ) -> TabSystemAction {
    .newTabRequested(
      byTab: openerTabID,
      modifierFlags: modifierFlags,
      completion: { [weak self] newTabPolicy in
        guard let self else { return }

        let groupID: TabGroupID? =
          switch newTabPolicy {
          case .cancel:
            nil
          case .continue:
            model(forTab: openerTabID).groupID
          case .continueWithGroup(let groupID):
            groupID
          }
        guard let groupID else { return }

        let groupModel = model(forGroup: groupID)
        let groupPolicy = policy(forGroup: groupID)

        let index: Int =
          if newTabPolicy == .continue {
            groupPolicy.decideInsertionIndexForNewlyOpenedTab(
              inGroup: groupModel,
              openerTabID: openerTabID,
            )
          } else {
            groupPolicy.decideInsertionIndexForNewTab(inGroup: groupModel)
          }

        let tabID = TabID()
        let tabModel = makeTabModel(tabID: tabID, groupID: groupID)

        groupModel.tabIDs.insert(tabID, at: index)

        _ = liveTabsManager.create(forModel: tabModel, withWebContent: webContent)!

        if newTabPolicy == .continue {
          groupModel.extendMiniGroup(from: openerTabID, adding: tabID)

          #if os(macOS)
          let openAsBackgroundTab = modifierFlags.contains(.command)
          #elseif os(Windows)
          let openAsBackgroundTab = modifierFlags.contains(.control)
          #endif

          if !openAsBackgroundTab {
            select(tab: tabID)
          }
        }
      }
    )
  }
}