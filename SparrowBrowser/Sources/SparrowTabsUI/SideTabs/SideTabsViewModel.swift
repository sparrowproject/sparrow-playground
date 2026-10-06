import Foundation
import Observation
import OrderedCollections
import SparrowTabs
import SparrowToolbelt
import SparrowUI
import SparrowUIFoundation

public typealias SideTabsViewModelDependencies
  = TabViewModelDependencies

@Observable @MainActor
public final class SideTabsViewModel {
  public init(dependencies: SideTabsViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel
  }

  public var tabHeight: CGFloat = 30

  let groupModel: Handle<TabGroupModel>
  var tabViewModels = OrderedDictionary<TabID, TabViewModel>()

  var selectedTabIndex: Int? {
    tabViewModels.keys.firstIndex(of: groupModel.selectedTabModel.id)
  }

  var selectedTabViewModel: TabViewModel? {
    return tabViewModels[groupModel.selectedTabModel.id]
  }

  var draggedTabViewModel: TabViewModel? {
    selectedTabViewModel?.isDragging == true ? selectedTabViewModel : nil
  }

  func updateTabViewModels(for tabIDs: OrderedSet<TabID>) {
    let newViewModels = OrderedDictionary(uniqueKeysWithValues: tabIDs.map { tabID in
      (tabID, tabViewModels[tabID] ?? TabViewModel(dependencies: dependencies, tabID: tabID, style: .sideTabs))
    })
    tabViewModels = newViewModels
  }

  func handleDrag(of draggedTabID: TabID, toPositionOf otherTabID: TabID) {
    withAnimation {
      dependencies.tabSystem.move(tab: draggedTabID, toPositionOf: otherTabID)
    }
  }

  private let dependencies: SideTabsViewModelDependencies
}
