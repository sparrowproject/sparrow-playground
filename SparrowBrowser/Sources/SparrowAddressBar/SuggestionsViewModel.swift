import Observation
import SparrowSuggest

public typealias SuggestionsViewModelDependencies
  = SuggestServiceProviding

@Observable
@MainActor
final class SuggestionsViewModel {
  init(dependencies: SuggestionsViewModelDependencies) {
    self.dependencies = dependencies
  }

  var suggestionResults: [SuggestQueryResult]? {
    suggestQueryModel?.completions
  }

  var numSuggestionResults: Int {
    suggestionResults?.count ?? 0
  }

  var selectedSuggestionRow: Int?

  var selectedSuggestionResult: SuggestQueryResult? {
    selectedSuggestionRow.flatMap { suggestionResult(at: $0) }
  }

  func suggestionResult(at index: Int) -> SuggestQueryResult? {
    suggestQueryModel?.completions[safe: index]
  }

  func querySuggestions(for input: String) {
    pendingSuggestQuery?.cancel()
    let pendingSuggestQuery = dependencies.suggestService.queryCompletions(for: input)
    self.pendingSuggestQuery = pendingSuggestQuery

    suggestQueryModel = pendingSuggestQuery.model.transitionalModel(from: suggestQueryModel)

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
          suggestQueryModel = pendingSuggestQuery.model
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

  func moveSelectionUp() {
    if let selectedSuggestionRow {
      if selectedSuggestionRow > 0 {
        self.selectedSuggestionRow = selectedSuggestionRow - 1
      } else {
        self.selectedSuggestionRow = numSuggestionResults - 1
      }
    } else if numSuggestionResults > 0 {
      selectedSuggestionRow = 0
    } else {
      selectedSuggestionRow = nil
    }
  }

  func moveSelectionDown() {
    if let selectedSuggestionRow {
      self.selectedSuggestionRow = (selectedSuggestionRow + 1) % numSuggestionResults
    } else if numSuggestionResults > 0 {
      selectedSuggestionRow = 0
    } else {
      selectedSuggestionRow = nil
    }
  }

  func moveSelectionToNextSearch() {
    guard let selectedSuggestionResult, let suggestionResults else { return }

    switch selectedSuggestionResult.kind {
    case .search:
      if let index = suggestionResults.firstIndex(where: { $0.isChat }) {
        selectedSuggestionRow = index
      }
    case .chat, .navigation:
      if let index = suggestionResults.firstIndex(where: { $0.isSearch }) {
        selectedSuggestionRow = index
      }
    }
  }

  private let dependencies: SuggestionsViewModelDependencies
  private var suggestQuery: SuggestQuery?
  private var suggestQueryModel: SuggestQueryModel?

  // Preserve the existing `suggestQuery` until the new one loads. This way we
  // minimize flicker while the query is running.
  private var pendingSuggestQuery: SuggestQuery?
}