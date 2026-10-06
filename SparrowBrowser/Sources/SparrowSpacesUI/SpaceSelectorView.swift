import Foundation
import SparrowDesignSystem
import SparrowTabs
import SparrowUI

public struct SpaceSelectorView: View {
  public enum Action {
    case activate(groupID: TabGroupID)
    case createScratchSpace
    case createSavedSpace(row: Int, col: Int)
  }

  public init(viewModel: SpaceSelectorViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      spaceChipView(for: viewModel.scratchChipViewModel)
        .offset(
          x: layout.offsetX(for: viewModel.scratchChipViewModel),
          y: layout.offsetY(for: viewModel.scratchChipViewModel),
        )

      Rectangle()
        .fill(StandardColors.border.opacity(0.7))
        .height(Metrics.borderWidth)
        .offset(y: Metrics.buttonSize + 2 * Metrics.padding)

      savedSpacesTitle
        .offset(x: layout.savedTitleOrigin.x, y: layout.savedTitleOrigin.y)

      Repeated(viewModel.savedChipViewModels.values) { chipViewModel in
        spaceChipView(for: chipViewModel)
          .offset(x: layout.offsetX(for: chipViewModel), y: layout.offsetY(for: chipViewModel))
      }

      IfLet(viewModel.draggingChipViewModel) { chipViewModel in
        SpaceChipView(viewModel: chipViewModel) { _ in }
          .width(Metrics.buttonSize)
          .height(Metrics.buttonSize)
          .offset(x: dragChipOffset?.x ?? 0, y: dragChipOffset?.y ?? 0)
      }
    }
    .width(layout.width)
    .height(layout.height)
    .onChange(of: (viewModel.numSavedRows, viewModel.numCols)) { _ in
      layout = computeLayout()
    }
  }

  private enum Metrics {
    static let buttonSize: CGFloat = 40
    static let padding: CGFloat = StandardMetrics.buttonCornerRadius
    static let borderWidth: CGFloat = 1
    static let titleBoxHeight: CGFloat = 20
  }

  @MainActor
  private struct Layout: Equatable {
    let numCols: Int
    let numSavedRows: Int
    let width: CGFloat
    let height: CGFloat
    let chips: [SpaceChipViewModel.ID: CGPoint]
    let savedTitleOrigin: CGPoint
    
    static var zero = Layout(
      numCols: 0,
      numSavedRows: 0,
      width: 0,
      height: 0,
      chips: [:],
      savedTitleOrigin: .zero,
    )

    func offsetX(for chip: SpaceChipViewModel) -> CGFloat {
      chips[chip.id]?.x ?? 0
    }

    func offsetY(for chip: SpaceChipViewModel) -> CGFloat {
      chips[chip.id]?.y ?? 0
    }

    func hitTest(point: CGPoint) -> SpaceChipViewModel.ID? {
      var candidates = [SpaceChipViewModel.ID: CGFloat]()
      for chip in chips {
        let chipSize = CGSize(width: Metrics.buttonSize, height: Metrics.buttonSize)
        let dragFrame = CGRect(origin: point, size: chipSize)
        let chipFrame = CGRect(origin: chip.value, size: chipSize)
        let area = dragFrame.intersection(chipFrame).area
        if area > 0 {
          candidates[chip.key] = area
        }
      }
      return candidates.max { $0.value < $1.value }?.key
    }
  }

  private let viewModel: SpaceSelectorViewModel
  private let action: (Action) -> Void
  @State private var layout = Layout.zero
  @State private var dragChipOffset: CGPoint?

  private var savedSpacesTitle: some View {
    Group {
      Text("Saved Spaces")
        .font(.system(size: 11))
        .alignment(.leading)
    }
    .height(Metrics.titleBoxHeight)
  }

  private func computeLayout() -> Layout {
    let numCols = viewModel.numCols
    let numSavedRows = viewModel.numSavedRows

    let width = (CGFloat(numCols) * Metrics.buttonSize) + (CGFloat(numCols + 1) * Metrics.padding)
    let height = (CGFloat(numSavedRows + 1) * Metrics.buttonSize)
      + (CGFloat(numSavedRows + 2) * Metrics.padding)
      + Metrics.padding + Metrics.borderWidth
      + Metrics.padding + Metrics.titleBoxHeight

    func offsetX(for chip: SpaceChipViewModel) -> CGFloat {
      CGFloat(chip.col) * (Metrics.buttonSize + Metrics.padding) + Metrics.padding
    }

    func offsetY(for chip: SpaceChipViewModel) -> CGFloat {
      switch chip.section {
      case .scratch:
        Metrics.padding
      case .saved:
        (CGFloat(chip.row) + 1) * (Metrics.buttonSize + Metrics.padding)
          + 2 * Metrics.padding
          + Metrics.borderWidth
          + Metrics.padding + Metrics.titleBoxHeight
      }
    }

    var chips = [SpaceChipViewModel.ID: CGPoint]()
    chips[viewModel.scratchChipViewModel.id] = .init(
      x: offsetX(for: viewModel.scratchChipViewModel),
      y: offsetY(for: viewModel.scratchChipViewModel),
    )
    for chip in viewModel.savedChipViewModels.values {
      chips[chip.id] = .init(x: offsetX(for: chip), y: offsetY(for: chip))
    }

    let savedTitleOrigin = CGPoint(
      x: Metrics.padding,
      y: Metrics.padding + Metrics.buttonSize + 2 * Metrics.padding + Metrics.borderWidth,
    )

    return .init(
      numCols: numCols,
      numSavedRows: numSavedRows,
      width: width,
      height: height,
      chips: chips,
      savedTitleOrigin: savedTitleOrigin,
    )
  }

  private func spaceChipView(for chipViewModel: SpaceChipViewModel) -> some View {
    Group {
      SpaceChipView(viewModel: chipViewModel) {
        handleChipAction($0, for: chipViewModel)
      }
    }
    .width(Metrics.buttonSize)
    .height(Metrics.buttonSize)
    .onPointerDragged {
      guard chipViewModel.groupID != nil else { return }
      viewModel.draggingChipViewModel = chipViewModel.clone()
      chipViewModel.hideSpace = true
      if dragChipOffset == nil {
        dragChipOffset = CGPoint(x: layout.offsetX(for: chipViewModel), y: layout.offsetY(for: chipViewModel))
      }
      dragChipOffset!.x += $0.delta.x
      dragChipOffset!.y += $0.delta.y
    }
    .onPointerUp {
      if let draggingChipViewModel = viewModel.draggingChipViewModel, draggingChipViewModel.id == chipViewModel.id {
        chipViewModel.hideSpace = false
        if
          let dragChipOffset,
          let chipID = layout.hitTest(point: dragChipOffset),
          let dropTargetViewModel = viewModel.chipViewModel(for: chipID)
        {
          viewModel.moveSpace(from: chipViewModel, to: dropTargetViewModel)
        }
        viewModel.draggingChipViewModel = nil
        dragChipOffset = nil
      }
    }
  }

  private func handleChipAction(_ action: SpaceChipView.Action, for chipViewModel: SpaceChipViewModel) {
    switch action {
    case .clicked:
      handleChipClicked(chipViewModel: chipViewModel)
    case .command(let commandID):
      viewModel.handleChipCommand(chipViewModel: chipViewModel, commandID: commandID).flatMap { self.action($0) }
    }
  }

  private func handleChipClicked(chipViewModel: SpaceChipViewModel) {
    if let groupID = chipViewModel.groupID {
      action(.activate(groupID: groupID))
    } else if chipViewModel.section == .scratch {
      action(.createScratchSpace)
    } else if chipViewModel.section == .saved {
      action(.createSavedSpace(row: chipViewModel.row, col: chipViewModel.col))
    }
  }
}