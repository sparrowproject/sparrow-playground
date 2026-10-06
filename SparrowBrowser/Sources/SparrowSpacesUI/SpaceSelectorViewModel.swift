import Observation
import OrderedCollections
import SparrowSpaces
import SparrowTabs
import SparrowToolbelt
import SparrowWindowModel

public typealias SpaceSelectorViewModelDependencies
  = SpaceChipViewModelDependencies

@Observable
@MainActor
public final class SpaceSelectorViewModel {
  public init(dependencies: SpaceSelectorViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel

    let isDragging = Handle<Bool>(false)

    scratchChipViewModel = .init(
      dependencies: dependencies,
      id: .init(section: .scratch, row: 0, col: 0),
      isDragging: { isDragging.value },
    )

    savedChipViewModels = .init(uniqueKeysWithValues: (0..<(numSavedRows * numCols)).map { [numCols] index in
      let chip = SpaceChipViewModel(
        dependencies: dependencies,
        id: .init(section: .saved, row: index / numCols, col: index % numCols),
        isDragging: { isDragging.value },
      )
      return (chip.id, chip)
    })

    self.isDragging = isDragging
  }

  // TODO: make these configurable
  let numSavedRows: Int = 5
  let numCols: Int = 4

  let isDragging: Handle<Bool>

  // TODO: add pagination
  // var numPages: Int = 1

  let scratchChipViewModel: SpaceChipViewModel
  let savedChipViewModels: OrderedDictionary<SpaceChipViewModel.ID, SpaceChipViewModel>

  var draggingChipViewModel: SpaceChipViewModel? {
    didSet {
      isDragging.value = draggingChipViewModel != nil
    }
  }

  func chipViewModel(for id: SpaceChipViewModel.ID) -> SpaceChipViewModel? {
    if id == scratchChipViewModel.id {
      scratchChipViewModel
    } else {
      savedChipViewModels[id]
    }
  }

  func moveSpace(from sourceViewModel: SpaceChipViewModel, to targetViewModel: SpaceChipViewModel) {
    guard let sourceGroupID = sourceViewModel.groupID else {
      return
    }

    let spaceGridModel = dependencies.spaceGridModel
    let browserWindowModel = dependencies.browserWindowModel

    let targetRow = targetViewModel.row
    let targetCol = targetViewModel.col

    if sourceViewModel.section == .scratch {
      guard
        targetViewModel.section == .saved,
        spaceGridModel[row: targetRow, col: targetCol] == nil
      else {
        return
      }

      browserWindowModel.scopedSpaces.remove(sourceGroupID)

      spaceGridModel[row: targetRow, col: targetCol] = sourceGroupID
    } else {
      let sourceRow = sourceViewModel.row
      let sourceCol = sourceViewModel.col

      if targetViewModel.section == .scratch {
        guard targetViewModel.groupID == nil else { return }

        browserWindowModel.scopedSpaces.append(sourceGroupID)

        spaceGridModel[row: sourceRow, col: sourceCol] = nil
      } else {
        let targetGroupID = targetViewModel.groupID

        spaceGridModel[row: sourceRow, col: sourceCol] = targetGroupID
        spaceGridModel[row: targetRow, col: targetCol] = sourceGroupID
      }
    }
  }

  func handleChipCommand(chipViewModel: SpaceChipViewModel, commandID: SpaceChipCommand.ID) -> SpaceSelectorView.Action? {
    print(">>> handleChipCommand, id: \(commandID)")

    switch commandID {
    case .activate:
      return chipViewModel.groupID.flatMap { .activate(groupID: $0) }

    case .save:
      guard
        let groupID = chipViewModel.groupID,
        chipViewModel.section == .scratch
      else {
        return nil
      }

      dependencies.browserWindowModel.scopedSpaces.remove(groupID)

      let spaceGridModel = dependencies.spaceGridModel

      // Find the first available open spot in the spaces grid.
      for row in 0..<spaceGridModel.numRows {
        for col in 0..<spaceGridModel.numCols {
          if spaceGridModel[row: row, col: col] == nil {
            spaceGridModel[row: row, col: col] = groupID
          }
        }
      }

    case .delete:
      guard
        let groupID = chipViewModel.groupID,
        chipViewModel.section == .saved,
        !dependencies.windowSystemModel.browserWindows.values.contains(where: { $0.groupID == groupID })
      else {
        return nil
      }

      dependencies.spaceGridModel[row: chipViewModel.row, col: chipViewModel.col] = nil
      dependencies.tabSystem.remove(group: groupID)
    }

    return nil
  }

  private let dependencies: SpaceSelectorViewModelDependencies
  private let groupModel: Handle<TabGroupModel>
}