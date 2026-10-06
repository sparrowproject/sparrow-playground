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
    print(">>> handleLiveTabsChanged [self: \(ObjectIdentifier(self))] for \(groupModel.id.id), count: \(liveTabs.count)")
    webContentViewModel.allWebContent = liveTabs.map(\.webContent)
  }

  // func handleTabIDsChange(_ tabIDs: OrderedSet<TabID>) {
  //   webContentViewModel.allWebContent = tabIDs.compactMap {
  //     dependencies.tabSystem.liveTab(forTab: $0, createIfNeeded: false)?.webContent
  //   }
  // }

  func handleSelectedTabChanged(_ tabID: TabID) {
    let liveTab = dependencies.tabSystem.liveTab(forTab: tabID)
    // let selectedWebContent = liveTab?.webContent
    // if let selectedWebContent, !webContentViewModel.allWebContent.contains(where: { $0 === selectedWebContent }) {
    //   webContentViewModel.allWebContent.append(selectedWebContent)
    // }
    webContentViewModel.selectedWebContent = liveTab?.webContent
  }
}