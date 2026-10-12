import Observation
import SparrowTabs
import SparrowToolbelt
import SparrowWeb

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
  public internal(set) var isEditorFocused: Bool?

  public internal(set) var searchString: String = "" {
    didSet {
      findNext()
    }
  }

  public func showEditor() {
    if isEditorVisible {
      isEditorFocused = true
    } else {
      isEditorVisible = true
    }
  }

  public func hideEditor() {
    isEditorVisible = false
  }

  public func findNext() {
    webContent?.find(searchString, backwards: false) { _ in }
  }

  public func findPrevious() {
    webContent?.find(searchString, backwards: true) { _ in }
  }

  private let dependencies: FindInPageViewModelDependencies
  private let groupModel: Handle<TabGroupModel>

  private var webContent: WebContent? {
    dependencies.tabSystem.liveTab(forTab: groupModel.selectedTabModel.value)?.webContent
  }
}

extension FindInPageViewModel: @MainActor Identifiable {
  public var id: ObjectIdentifier { .init(self) }
}