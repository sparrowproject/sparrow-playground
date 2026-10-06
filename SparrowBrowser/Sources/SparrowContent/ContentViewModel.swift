import Foundation
import Observation
import SparrowContentToolbar
import SparrowTabs
import SparrowToolbelt

public typealias ContentViewModelDependencies
  = ContentBodyViewModelDependencies
  & ContentToolbarViewModelDependencies

@Observable @MainActor
public final class ContentViewModel {
  public init(dependencies: ContentViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.groupModel = groupModel
    contentBodyViewModel = .init(dependencies: dependencies, groupModel: groupModel)
    contentToolbarViewModel = .init(dependencies: dependencies, groupModel: groupModel)
  }

  public let groupModel: Handle<TabGroupModel>
  public let contentBodyViewModel: ContentBodyViewModel
  public let contentToolbarViewModel: ContentToolbarViewModel

  public var toolbarHeight: CGFloat = .zero
}