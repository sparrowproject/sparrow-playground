import Foundation
import Observation
import OrderedCollections
import SparrowTabs
import SparrowToolbelt
import SparrowUI
import SparrowUIFoundation

public typealias TopTabsViewModelDependencies
  = TabViewModelDependencies
  & TabSystemProviding

@Observable @MainActor
public final class TopTabsViewModel {
  public init(dependencies: TopTabsViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel
  }

  public var insets: EdgeInsets = .zero

  #if os(Windows)
  public var nonClientPassthroughRects = [CGRect]()
  #endif

  let groupModel: Handle<TabGroupModel>
  var tabViewModels = OrderedDictionary<TabID, TabViewModel>()
  var lockedTabCount: Int?

  var selectedTabID: TabID {
    groupModel.selectedTabModel.id
  }

  var selectedTabViewModel: TabViewModel? {
    tabViewModels[groupModel.selectedTabModel.id]
  }

  var draggedTabViewModel: TabViewModel? {
    selectedTabViewModel?.isDragging == true ? selectedTabViewModel : nil
  }

  func updateTabViewModels(for tabIDs: OrderedSet<TabID>) {
    let newViewModels = OrderedDictionary(uniqueKeysWithValues: tabIDs.map { tabID in
      (tabID, tabViewModels[tabID] ?? TabViewModel(dependencies: dependencies, tabID: tabID, style: .topTabs))
    })

    let diff = newViewModels.keys.difference(from: tabViewModels.keys)
    if !diff.removals.isEmpty {
      updateIsLayoutLockedAfterRemoval()
    }

    tabViewModels = newViewModels
  }

  func handleDrag(of draggedTabID: TabID, toPositionOf otherTabID: TabID) {
    let tabSystem = dependencies.tabSystem
    withAnimation {
      tabSystem.move(tab: draggedTabID, toPositionOf: otherTabID)
    }
  }

  private let dependencies: TopTabsViewModelDependencies
  private var unlockTask: Task<Void, Never>?

  private var isHoveringAnyTab: Bool {
    tabViewModels.values.contains { $0.isHovered }
  }

  private func updateIsLayoutLockedAfterRemoval() {
    guard unlockTask == nil else { return }
    lockedTabCount = tabViewModels.count
    unlockTask = Task<Void, Never> {
      repeat {
        try? await Task.sleep(for: .seconds(1))
      } while isHoveringAnyTab

      withAnimation { [self] in
        lockedTabCount = nil
      }

      unlockTask = nil
    }
  }
}