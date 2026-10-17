import Observation
import SparrowToolbelt

@MainActor
public protocol TabUndoManager {
  var model: TabUndoModel { get }

  func undo()
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

  func undo() {
    print(">>> undo!")
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