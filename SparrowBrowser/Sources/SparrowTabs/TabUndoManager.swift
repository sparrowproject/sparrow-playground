import Observation
import SparrowToolbelt

@MainActor
public protocol TabUndoManager {
  var model: TabUndoModel { get }

  func willRemoveTab(_: TabModel, from: TabGroupModel)
  func willRemoveTabGroup(_: TabGroupModel)
}

public protocol TabUndoManagerProviding {
  @MainActor
  var tabUndoManager: TabUndoManager { get }
}

extension Factory where Interface == TabUndoManager {
  public static func makeDefaultInstance() -> TabUndoManager {
    DefaultTabUndoManager()
  }

  public static func makeNoOpInstance() -> TabUndoManager {
    NoOpTabUndoManager()
  }
}

final class NoOpTabUndoManager: TabUndoManager {
  init() {}

  let model = TabUndoModel()

  func willRemoveTab(_: TabModel, from: TabGroupModel) {}
  func willRemoveTabGroup(_: TabGroupModel) {}
}

final class DefaultTabUndoManager: TabUndoManager {
  init() {}

  let model = TabUndoModel()

  func willRemoveTab(_ tabModel: TabModel, from groupModel: TabGroupModel) {
    model.push(.tab(tabModel, groupID: groupModel.id, tabIDs: groupModel.tabIDs))
  }

  func willRemoveTabGroup(_ groupModel: TabGroupModel) {
    model.push(.group(groupModel))
  }
}