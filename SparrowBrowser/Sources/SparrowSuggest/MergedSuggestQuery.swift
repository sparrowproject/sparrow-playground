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

  private func buildCompletions() -> [String] {
    var completions: [String] = []
    if !model.input.isEmpty {
      completions.append(model.input)
    }
    for completion in webSearchSuggestQuery.model.completions {
      if completion == model.input {
        continue
      }
      completions.append(completion)
    }
    return completions
  }
}