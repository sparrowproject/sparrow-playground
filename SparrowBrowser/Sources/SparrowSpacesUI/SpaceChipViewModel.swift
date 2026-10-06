import Observation
import SparrowSpaces
import SparrowTabs
import SparrowUI
import SparrowWindowModel

public typealias SpaceChipViewModelDependencies
  = BrowserWindowModelProviding
  & SpaceGridModelProviding
  & TabSystemProviding
  & WindowSystemModelProviding

@Observable
@MainActor
final class SpaceChipViewModel {
  struct ID: Hashable, Equatable {
    let section: SpaceSection
    let row: Int
    let col: Int
  }

  init(
    dependencies: SpaceChipViewModelDependencies,
    id: ID,
    isDragging: @escaping () -> Bool,
  ) {
    self.dependencies = dependencies
    self.id = id
    self.isDragging = isDragging
  }

  let dependencies: SpaceChipViewModelDependencies
  let id: ID
  let isDragging: () -> Bool

  var hideSpace = false

  var section: SpaceSection {
    id.section
  }

  var row: Int {
    id.row
  }

  var col: Int {
    id.col
  }

  var groupModel: TabGroupModel? {
    let groupID: TabGroupID? =
      if section == .scratch {
        dependencies.browserWindowModel.scopedSpaces[safe: row * col]
      } else {
        dependencies.spaceGridModel[row: row, col: col]
      }
    return groupID.flatMap { dependencies.tabSystem.model(forGroup: $0) }
  }

  var selectedGroupID: TabGroupID {
    dependencies.browserWindowModel.groupID
  }

  var groupID: TabGroupID? {
    groupModel?.id
  }

  var groupIsOpenInAnotherWindow: Bool {
    if isSelected {
      return false
    }
    if dependencies.windowSystemModel.browserWindows.values.contains(where: { $0.groupID == groupID }) {
      return true
    }
    return false
  }

  var hasSpace: Bool {
    groupID != nil
  }

  var isSelected: Bool {
    selectedGroupID == groupID
  }

  var contextMenuData: MenuData {
    switch section {
    case .scratch:
      .init(items: [
        .command(activateCommand),
        .command(SpaceChipCommands.save),
      ])
    case .saved:
      .init(items: [
        .command(activateCommand),
        .command(deleteCommand),
      ])
    }
  }

  func clone() -> Self {
    .init(
      dependencies: dependencies,
      id: id,
      isDragging: isDragging,
    )
  }

  private var activateCommand: some Command {
    with(SpaceChipCommands.activate) {
      $0.isEnabled = !isSelected
      $0.title = groupIsOpenInAnotherWindow ? "Bring window to front" : "Show this space"
    }
  }

  private var deleteCommand: some Command {
    with(SpaceChipCommands.delete) {
      $0.isEnabled = !isSelected && !groupIsOpenInAnotherWindow
    }
  }
}

extension SpaceChipViewModel: @MainActor Identifiable {}