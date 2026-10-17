import Observation
import SparrowToolbelt

@MainActor
public protocol TabUndoManager {
  var model: TabUndoModel { get }

  var canUndo: Bool { get }

  /// Returns the `Entry` that was reverted (if any).
  func undo() -> TabUndoModel.Entry?
}

public protocol TabUndoManagerProviding {
  @MainActor
  var tabUndoManager: TabUndoManager { get }
}

public typealias TabUndoManagerDependencies
  = TabSystemProviding

extension Factory where Interface == TabUndoManager {
  public static func makeDefaultInstance(dependencies: TabUndoManagerDependencies) -> TabUndoManager {
    DefaultTabUndoManager(dependencies: dependencies)
  }
}

final class DefaultTabUndoManager: TabUndoManager {
  init(dependencies: TabUndoManagerDependencies) {
    self.dependencies = dependencies

    // TODO: Consider lifecycle implications here.
    dependencies.tabSystem.addObserver(self)
  }

  let model = TabUndoModel()

  var canUndo: Bool {
    !model.entries.isEmpty
  }

  func undo() -> TabUndoModel.Entry? {
    print(">>> undo!")

    guard let entry = model.pop() else { return nil }

    switch entry {
    case .tab(let tabModel, let groupID, let tabIDs):
      undoRemoveTab(tabModel, groupID: groupID, tabIDs: tabIDs)
    case .group(let groupModel, let tabModels):
      undoRemoveGroup(groupModel, tabModels: tabModels)
    }

    return entry
  }

  private let dependencies: TabUndoManagerDependencies

  private func undoRemoveTab(_ tabModel: TabModel, groupID: TabGroupID, tabIDs: [TabID]) {
    let tabSystemModel = dependencies.tabSystem.model

    guard let groupModel = tabSystemModel.groups[groupID] else {
      print(">>> failed to undo tab removal: group model not found!")
      return
    }

    guard let oldIndex = tabIDs.firstIndex(of: tabModel.id) else {
      print(">>> failed to undo tab removal: tab not found in given tabIDs!")
      return
    }

    var insertionIndex = oldIndex
    if oldIndex > 0 {
      // Validate / improve insertion index by inspecting nearby tabs.
      let tabIDBefore = tabIDs[oldIndex - 1]
      if let indexOfTabBefore = groupModel.tabIDs.firstIndex(of: tabIDBefore) {
        insertionIndex = indexOfTabBefore + 1
      }
    }
    if insertionIndex >= groupModel.tabIDs.count {
      insertionIndex = groupModel.tabIDs.count
    }

    tabSystemModel.tabs[tabModel.id] = tabModel
    groupModel.tabIDs.insert(tabModel.id, at: insertionIndex)
  }

  private func undoRemoveGroup(_ groupModel: TabGroupModel, tabModels: [TabModel]) {
    let tabSystemModel = dependencies.tabSystem.model

    for tabModel in tabModels {
      tabSystemModel.tabs[tabModel.id] = tabModel
    }
    tabSystemModel.groups[groupModel.id] = groupModel
  }
}

extension DefaultTabUndoManager: TabSystemObserver {
  func willRemoveTab(_ tabModel: TabModel, from groupModel: TabGroupModel) {
    model.push(.tab(tabModel, groupID: groupModel.id, tabIDs: groupModel.tabIDs.elements))
  }

  func willRemoveTabGroup(_ groupModel: TabGroupModel) {
    model.push(.group(groupModel, tabModels: groupModel.tabIDs.map {
      dependencies.tabSystem.model(forTab: $0)
    }))
  }
}