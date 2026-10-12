import Observation
import SparrowTabs
import SparrowToolbelt

public typealias FindInPageViewModelDependencies
  = TabSystemProviding

@Observable
@MainActor
public final class FindInPageViewModel {
  public init(dependencies: FindInPageViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel
  }

  public internal(set) var isEditorVisible = false
  public internal(set) var searchString: String = ""

  public func showFindEditor() {
    print(">>> showFindEditor")
    isEditorVisible = true
  }

  public func findNext() {
    print(">>> findNext")
  }

  public func findPrevious() {
    print(">>> findPrevious")
  }

  private let dependencies: FindInPageViewModelDependencies
  private let groupModel: Handle<TabGroupModel>
}