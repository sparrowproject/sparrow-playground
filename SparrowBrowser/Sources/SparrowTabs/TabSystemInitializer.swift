import Foundation

@MainActor
public protocol TabSystemInitializer: Sendable {
  func insertTab(
    id: TabID,
    url: URL?,
    title: String?,
    faviconURL: URL?,
    interactionState: Data?,
  )

  func insertTabGroup(
    id: TabGroupID,
    tabIDs: [TabID],
    selectedTabID: TabID?,
  )
}

final class DefaultTabSystemInitializer: TabSystemInitializer {
  init(model: TabSystemModel) {
    self.model = model
  }

  func insertTab(
    id: TabID,
    url: URL?,
    title: String?,
    faviconURL: URL?,
    interactionState: Data?,
  ) {
    // The `groupID` will be corrected inside `finish`.
    let tabModel = TabModel(id: id, groupID: .invalid)
    tabModel.webContentModel = .init(
      url: url,
      title: title,
      faviconURL: faviconURL,
      interactionState: interactionState,
    )
    provisionalTabs[id] = tabModel
  }

  func insertTabGroup(
    id: TabGroupID,
    tabIDs: [TabID],
    selectedTabID: TabID?,
  ) {
    let groupModel = TabGroupModel(id: id)
    groupModel.tabIDs = .init(tabIDs)
    // This will be updated to be the actual tab model in `finish`.
    groupModel.selectedTabModel = .init(selectedTabID.flatMap({ .init(id: $0, groupID: id) }) ?? .invalid)
    provisionalGroups[id] = groupModel
  }

  func commit() {
    // Merges validated items into the model, clobbering any existing items that match.

    for group in provisionalGroups.values {
      for tabID in group.tabIDs {
        if let tabModel = provisionalTabs.removeValue(forKey: tabID) {
          tabModel.groupID = group.id
          setTabModel(tabModel)
          if group.selectedTabModel.id == tabModel.id {
            group.selectedTabModel.value = tabModel
          }
        }
      }
      setGroupModel(group)
    }

    // TODO: cleanup unreferenced tabs!
    if !provisionalTabs.isEmpty {
      print(">>> Warning: \(provisionalTabs.count) unreferenced tab(s) discovered!")
    }
  }

  private let model: TabSystemModel
  private var provisionalTabs = [TabID: TabModel]()
  private var provisionalGroups = [TabGroupID: TabGroupModel]()

  private func setTabModel(_ tabModel: TabModel) {
    if model.tabs.keys.contains(tabModel.id) {
      print(">>> Warning: clobbering existing tab model!")
    }
    model.tabs[tabModel.id] = tabModel
  }

  private func setGroupModel(_ groupModel: TabGroupModel) {
    if model.groups.keys.contains(groupModel.id) {
      print(">>> Warning: clobbering existing tab group model!")
    }
    model.groups[groupModel.id] = groupModel
  }
}