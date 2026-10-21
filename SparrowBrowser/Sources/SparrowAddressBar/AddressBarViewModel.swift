import Foundation
import Observation
import SparrowSuggest

public typealias AddressBarViewModelDependencies
  = SuggestionsViewModelDependencies

@Observable @MainActor
public final class AddressBarViewModel {
  public init(dependencies: AddressBarViewModelDependencies) {
    self.dependencies = dependencies

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
  }

  public func handleURLChanged(_ url: URL?) {
    guard mode == .placeholder else { return }

    let hostname = url?.host() ?? ""

    content.placeholderValue = hostname
    content.editorValue = url?.absoluteString ?? ""
   }

  enum Mode {
    case placeholder
    case editor
  }

  let suggestionsViewModel: SuggestionsViewModel
  var mode = Mode.placeholder
  var placeholderPositionInHost: CGPoint?
  var placeholderSize = CGSize.zero

  private let dependencies: AddressBarViewModelDependencies
}

extension AddressBarViewModel: @MainActor Identifiable {
  public var id: ObjectIdentifier { .init(self) }
}