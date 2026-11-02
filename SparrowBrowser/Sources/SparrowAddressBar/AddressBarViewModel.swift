import Foundation
import Observation
import SparrowSuggest
import SparrowTabs
import SparrowToolbelt

public typealias AddressBarViewModelDependencies
  = SuggestionsViewModelDependencies

@Observable @MainActor
public final class AddressBarViewModel {
  public init(dependencies: AddressBarViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel

    suggestionsViewModel = .init(dependencies: dependencies)
  }

  @MainActor
  public struct Content {
    public let placeholderValue: String
    public let editorValue: String
    public let editorSelection: Range<String.Index>?
  }

  public var editorHasFocus: Bool {
    // mode == .editor
    tabState.editorHasFocus == true
  }

  public func focusEditor(blank: Bool = false, selectAll: Bool = true) {
    switch mode {
    case .placeholder:
      if blank {
        tabState.editorString = ""
      }
      if selectAll {
        tabState.editorSelection = tabState.editorString.startIndex..<tabState.editorString.endIndex
      }
      tabState.editorHasFocus = true
    case .editor:
      suggestionsViewModel.moveSelectionToNextSearch()
    }
  }

  public func dismissEditor() {
    tabState.editorHasFocus = false
    handleURLChanged(url) // Put the current URL back.
  }

  enum Mode {
    case placeholder
    case editor
  }

  let suggestionsViewModel: SuggestionsViewModel
  var placeholderPositionInHost: CGPoint?
  var placeholderSize = CGSize.zero

  var mode: Mode {
    if editorHasFocus {
      .editor
    } else {
      .placeholder
    }
  }

  var placeholderString: String {
    tabState.placeholderString
  }

  var editorString: String {
    tabState.editorString
  }

  var editorSelection: Range<String.Index> {
    tabState.editorSelection
  }

  var url: URL? {
    groupModel.selectedTabModel.url
  }

  var tabID: TabID {
    groupModel.selectedTabModel.id
  }

  var tabState: AddressBarTabState {
    groupModel.selectedTabModel.addressBarTabState ?? {
      let state = AddressBarTabState()
      groupModel.selectedTabModel.value.addressBarTabState = state
      return state
    }()
  }

  func handleURLChanged(_ url: URL?) {
    guard mode == .placeholder else { return }

    let hostname = url?.host() ?? ""

    tabState.placeholderString = hostname
    tabState.editorString = url?.absoluteString ?? ""
  }

  func handleTabChange() {
    // TODO: Adjust behavior based on selected tab.
  }

  private let dependencies: AddressBarViewModelDependencies
  private let groupModel: Handle<TabGroupModel>
}

extension AddressBarViewModel: @MainActor Identifiable {
  public var id: ObjectIdentifier { .init(self) }
}