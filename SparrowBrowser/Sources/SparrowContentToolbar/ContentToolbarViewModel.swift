import Foundation
import Observation
import SparrowAddressBar
import SparrowProfileModel
import SparrowSpacesUI
import SparrowTabs
import SparrowToolbelt
import SparrowUI
import SparrowUIFoundation
import SparrowWeb

public typealias ContentToolbarViewModelDependencies
  = AddressBarViewModelDependencies
  & ProfileIDProviding
  & SpaceSelectorViewModelDependencies
  & TabSystemProviding

@Observable @MainActor
public final class ContentToolbarViewModel {
  public init(dependencies: ContentToolbarViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel

    addressBarViewModel = .init(dependencies: dependencies)
    spaceSelectorViewModel = .init(dependencies: dependencies, groupModel: groupModel)
  }

  public let groupModel: Handle<TabGroupModel>
  public let addressBarViewModel: AddressBarViewModel
  public let spaceSelectorViewModel: SpaceSelectorViewModel

  // Optional insets to allow content to be overlaid on top of the content toolbar (e.g., window buttons).
  public var insets: EdgeInsets = .zero

  public var tabModel: Handle<TabModel> {
    groupModel.selectedTabModel
  }

  public var disableSpaceSelector: Bool {
    dependencies.profileID.isIncognito
  }

  public func handleURLChanged(_ url: URL?) {
    addressBarViewModel.handleURLChanged(url)
  }

  let backListMenuData = MenuData()
  let forwardListMenuData = MenuData()

  func updateBackListMenuData(colorScheme: ColorScheme) {
    print(">>> updateBackListMenuData")
    guard let liveTab = dependencies.tabSystem.liveTab(forTab: tabModel.value) else {
      backListMenuData.items = []
      return
    }
    backListMenuData.items = liveTab.webContent.backForwardList.backList.reversed().map {
      .command(BackForwardListCommand(item: $0, colorScheme: colorScheme))
    }
  }

  func updateForwardListMenuData(colorScheme: ColorScheme) {
    print(">>> updateForwardListMenuData")
    guard let liveTab = dependencies.tabSystem.liveTab(forTab: tabModel.value) else {
      forwardListMenuData.items = []
      return
    }
    forwardListMenuData.items = liveTab.webContent.backForwardList.forwardList.map {
      .command(BackForwardListCommand(item: $0, colorScheme: colorScheme))
    }
  }

  // func handleAddressBarAction(_ action: AddressBarView.Action) -> ContentToolbarView.Action? {
  
  //   switch action {
  //   case .submit(let text):
  //     print(">>> submit: \(text)")

  //     guard let url = URL.fromUserInput(text) else {
  //       // Reset back to the current tab model.
  //       handleURLChanged(tabModel.url)
  //       return
  //     }
   
  //     // TODO: Navigate the tab!
  //     dependencies.tabSystem.load(.init(url: url), inTab: tabModel.id)
  //   }
  // }

  func handleBackForwardMenuAction(_ action: Menu.Action) {
    guard let liveTab = dependencies.tabSystem.liveTab(forTab: tabModel.value) else { return }
    guard case .command(let command) = action else { return }

    let item = (command as! BackForwardListCommand).item
    liveTab.webContent.goTo(item)
  }

  private let dependencies: ContentToolbarViewModelDependencies
}

final class BackForwardListCommand: Command {
  init(item: any WebContentBackForwardListItem, colorScheme: ColorScheme) {
    self.item = item
    self.colorScheme = colorScheme
  }

  let item: any WebContentBackForwardListItem
  let colorScheme: ColorScheme

  var title: String { item.title ?? "" }
  var icon: ImageSource? { .pageFavicon(pageURL: item.url, colorScheme: colorScheme) }
  var isEnabled: Bool { true }
  var isToggled: Bool { false }
  var keybinding: Keybinding? { nil }
}
