import Foundation
import Observation
import SparrowCommands
import SparrowDesignSystem
import SparrowTabs
import SparrowUIFoundation

public typealias TabViewModelDependencies
  = TabSystemProviding

@Observable @MainActor
final class TabViewModel {
  init(dependencies: TabViewModelDependencies, tabID: TabID, style: TabsStyle) {
    self.dependencies = dependencies
    self.style = style
    tabModel = dependencies.tabSystem.model(forTab: tabID)
  }

  let tabModel: TabModel
  let style: TabsStyle
  var isExpanded = false
  var isHovered = false
  var dragOffset: CGPoint?

  var isDragging: Bool {
    dragOffset != nil
  }

  var tabID: TabID {
    tabModel.id
  }

  var icon: ImageSource? {
    tabModel.favicon
  }

  var titleText: String {
    tabModel.title ?? tabModel.url?.host() ?? ""
  }

  var isSelected: Bool {
    tabModel.isSelected
  }

  func isCommandEnabled(_ commandID: SparrowCommand.ID) -> Bool {
    let result: Bool = {
    switch commandID {
    case .closeOtherTabs:
      let groupModel = dependencies.tabSystem.model(forGroup: tabModel.groupID)
      return groupModel.tabIDs.count > 1
    case .closeTabsAfter:
      let groupModel = dependencies.tabSystem.model(forGroup: tabModel.groupID)
      guard let index = groupModel.tabIDs.firstIndex(of: tabID) else {
        assertionFailure("Cannot find tab in group!")
        return false
      }
      return index < (groupModel.tabIDs.count - 1)
    default:
      return true
    }
    }()
    print(">>> isCommandEnabled: \(commandID), result: \(result)")
    return result
  }

  private let dependencies: TabViewModelDependencies
}
