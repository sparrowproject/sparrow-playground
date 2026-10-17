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
      break
    case .group(let groupModel):
      break
    }

    return entry
  }

  private let dependencies: TabUndoManagerDependencies
}

extension DefaultTabUndoManager: TabSystemObserver {
  func willRemoveTab(_ tabModel: TabModel, from groupModel: TabGroupModel) {
    model.push(.tab(tabModel, groupID: groupModel.id, tabIDs: groupModel.tabIDs))
  }

  func willRemoveTabGroup(_ groupModel: TabGroupModel) {
    model.push(.group(groupModel))
  }
}