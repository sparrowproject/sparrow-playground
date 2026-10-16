import Observation
import SparrowToolbelt

@MainActor
public protocol TabUndoManager {
  var model: TabUndoModel { get }

  func willRemoveTab(_: TabModel, from: TabGroupModel)
  func didRemoveTab(_: TabID, from: TabGroupID)
  func willRemoveTabGroup(_: TabGroupModel)
  func didRemoveTabGroup(_: TabGroupID)
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
  func didRemoveTab(_: TabID, from: TabGroupID) {}
  func willRemoveTabGroup(_: TabGroupModel) {}
  func didRemoveTabGroup(_: TabGroupID) {}
}

final class DefaultTabUndoManager: TabUndoManager {
  init() {}

  let model = TabUndoModel()

  func willRemoveTab(_ tabModel: TabModel, from groupModel: TabGroupModel) {
    print(">>> willRemoveTab, id: \(tabModel.id), from: \(groupModel.id)")
  }

  func didRemoveTab(_ tabID: TabID, from groupID: TabGroupID) {
    print(">>> didRemoveTab, id: \(tabID), from: \(groupID)")
  }

  func willRemoveTabGroup(_ groupModel: TabGroupModel) {
    print(">>> willRemoveTabGroup, id: \(groupModel.id)")
  }

  func didRemoveTabGroup(_ groupID: TabGroupID) {
    print(">>> didRemoveTabGroup, id: \(groupID)")
  }
}