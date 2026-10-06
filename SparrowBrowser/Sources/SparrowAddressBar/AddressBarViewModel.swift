import Foundation
import Observation
import SparrowSuggest

public typealias AddressBarViewModelDependencies
  = SuggestServiceProviding

@Observable @MainActor
public final class AddressBarViewModel {
  public init(dependencies: AddressBarViewModelDependencies) {
    self.dependencies = dependencies
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
    if blank {
      content.editorValue = ""
    }
    if selectAll {
      content.editorSelection = content.editorValue.startIndex..<content.editorValue.endIndex
    }
    mode = .editor
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

  var mode = Mode.placeholder
  var placeholderPositionInHost: CGPoint?
  var placeholderSize = CGSize.zero

  var suggestQueryModel: SuggestQueryModel? {
    suggestQuery?.model
  }

  func querySuggestions(for input: String) {
    pendingSuggestQuery?.cancel()
    let pendingSuggestQuery = dependencies.suggestService.queryCompletions(for: input)
    self.pendingSuggestQuery = pendingSuggestQuery

    Task<Void, Never> {
      for await status in Observations({
        pendingSuggestQuery.model.status
      }) {
        if pendingSuggestQuery !== self.pendingSuggestQuery {
          break
        }
        if status == .done {
          suggestQuery?.cancel()
          suggestQuery = pendingSuggestQuery
          self.pendingSuggestQuery = nil
          break
        }
      }
    }
  }

  func clearSuggestions() {
    suggestQuery?.cancel()
    suggestQuery = nil

    pendingSuggestQuery?.cancel()
    pendingSuggestQuery = nil
  }

  private let dependencies: AddressBarViewModelDependencies

  private var suggestQuery: SuggestQuery?

  // Preserve the existing `suggestQuery` until the new one loads. This way we
  // minimize flicker while the query is running.
  private var pendingSuggestQuery: SuggestQuery?
}

extension AddressBarViewModel: @MainActor Identifiable {
  public var id: ObjectIdentifier { .init(self) }
}