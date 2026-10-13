import Observation
import OrderedCollections
import SparrowTabs
import SparrowToolbelt
import SparrowWeb

public typealias ContentBodyViewModelDependencies
  = TabSystemProviding
  & WebContentViewModelDependencies

@MainActor
@Observable
public final class ContentBodyViewModel {
  public init(dependencies: ContentBodyViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel

    webContentViewModel = .init(dependencies: dependencies)
  }

  public let webContentViewModel: WebContentViewModel

  let dependencies: ContentBodyViewModelDependencies
  let groupModel: Handle<TabGroupModel>

  var liveTabs: [LiveTab] {
    dependencies.tabSystem.model.liveTabs(forGroup: groupModel.id)
  }

  func handleLiveTabsChanged(_ liveTabs: [LiveTab]) {
    webContentViewModel.allWebContent = liveTabs.map(\.webContent)
  }

  func handleSelectedTabChanged(_ tabID: TabID) {
    let liveTab = dependencies.tabSystem.liveTab(forTab: tabID)
    webContentViewModel.selectedWebContent = liveTab?.webContent
  }
}