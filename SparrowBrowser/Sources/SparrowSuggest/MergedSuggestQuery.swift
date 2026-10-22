import Foundation
import Observation

final class MergedSuggestQuery: SuggestQuery {
  init(input: String, webSearchSuggestQuery: SuggestQuery) {
    self.webSearchSuggestQuery = webSearchSuggestQuery

    model = .init(input: input)
    model.completions = buildCompletions()

    queryTask = .init {
      guard !Task.isCancelled, model.status == .pending else {
        return
      }

      for await status in Observations({
        webSearchSuggestQuery.model.status
      }) {
        if status == .done {
          break
        }
      }

      guard !Task.isCancelled, model.status == .pending else {
        return
      }

      model.completions = buildCompletions()
      model.status = .done
      queryTask = nil
    }
  }

  let model: SuggestQueryModel

  func cancel() {
    queryTask?.cancel()
    queryTask = nil

    webSearchSuggestQuery.cancel()

    model.status = .done
  }

  private let webSearchSuggestQuery: SuggestQuery
  private var queryTask: Task<Void, Never>?

  private func buildCompletions() -> [SuggestQueryResult] {
    var completions: [SuggestQueryResult] = []
    if !model.input.isEmpty {
      if let url = URL.fromUserInput(model.input, withSearchFallback: false) {
        completions.append(.init(kind: .navigation(url), value: model.input, representsInput: true))
      }
      completions.append(.init(kind: .search, value: model.input, representsInput: true))
    }
    for completion in webSearchSuggestQuery.model.completions {
      if case .search = completion.kind, completion.value == model.input {
        continue
      }
      completions.append(completion)
    }
    if !model.input.isEmpty {
      completions.append(.init(kind: .chat, value: model.input, representsInput: true))
    }
    return completions
  }
}