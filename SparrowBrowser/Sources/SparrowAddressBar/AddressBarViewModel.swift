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
    public var placeholderValue: String = ""
    public var editorValue: String = "" {
      didSet {
        editorSelection = nil
      }
    }
    public var editorSelection: Range<String.Index>?
  }

  public internal(set) var content = Content()

  public var editorHasFocus: Bool {
    mode == .editor
  }

  public func focusEditor(blank: Bool = false, selectAll: Bool = true) {
    switch mode {
    case .placeholder:
      if blank {
        content.editorValue = ""
      }
      if selectAll {
        content.editorSelection = content.editorValue.startIndex..<content.editorValue.endIndex
      }
      mode = .editor
    case .editor:
      suggestionsViewModel.moveSelectionToNextSearch()
    }
  }

  public func dismissEditor() {
    mode = .placeholder
    handleURLChanged(url) // Put the current URL back.
  }

  enum Mode {
    case placeholder
    case editor
  }

  let suggestionsViewModel: SuggestionsViewModel
  var mode = Mode.placeholder
  var placeholderPositionInHost: CGPoint?
  var placeholderSize = CGSize.zero

  var url: URL? {
    groupModel.selectedTabModel.url
  }

  var tabID: TabID {
    groupModel.selectedTabModel.id
  }

  func handleURLChanged(_ url: URL?) {
    guard mode == .placeholder else { return }

    let hostname = url?.host() ?? ""

    content.placeholderValue = hostname
    content.editorValue = url?.absoluteString ?? ""
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