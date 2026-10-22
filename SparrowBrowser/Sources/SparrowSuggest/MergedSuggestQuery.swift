import Foundation
import Observation
import SparrowHistory

public typealias MergedSuggestQueryDependencies
  = TypedHistoryProviding
  & WebSearchSuggestQueryDependencies

final class MergedSuggestQuery: SuggestQuery {
  init(dependencies: MergedSuggestQueryDependencies, input: String) {
    self.dependencies = dependencies
    self.webSearchSuggestQuery = .init(dependencies: dependencies, input: input)

    model = .init(input: input)
    model.completions = buildCompletions()

    queryTask = .init { [webSearchSuggestQuery] in
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

  private let dependencies: MergedSuggestQueryDependencies
  private let webSearchSuggestQuery: WebSearchSuggestQuery
  private var queryTask: Task<Void, Never>?

  private func buildCompletions() -> [SuggestQueryResult] {
    var completions: [SuggestQueryResult] = []
    if !model.input.isEmpty {
      if
        let record = dependencies.typedHistory.queryRecord(matching: model.input),
        let result = SuggestQueryResult(from: record, withInput: model.input)
      {
        completions.append(result)
      } else {
        if let url = URL.fromUserInput(model.input, withSearchFallback: false) {
          completions.append(.init(
            kind: .navigation(url),
            value: model.input,
            selection: nil,
            representsInput: true,
            preferredMatch: true,
          ))
        }
        completions.append(.init(
          kind: .search,
          value: model.input,
          selection: nil,
          representsInput: true,
          preferredMatch: true,
        ))
      }
    }
    for completion in webSearchSuggestQuery.model.completions {
      if case .search = completion.kind, completion.value == model.input {
        continue
      }
      completions.append(completion)
    }
    if !model.input.isEmpty {
      completions.append(.init(
        kind: .chat,
        value: model.input,
        selection: nil,
        representsInput: true,
        preferredMatch: true,
      ))
    }
    return completions
  }
}

extension SuggestQueryResult {
  init?(from record: TypedHistoryRecord, withInput input: String) {
    switch record.kind {
    case .navigation:
      guard let url = URL.fromUserInput(record.value, withSearchFallback: false) else { return nil }
      self.init(
        kind: .navigation(url),
        value: record.value,
        selection: rangeAfterPrefix(input, in: record.value),
        representsInput: false,
        preferredMatch: true,
      )
    case .search:
      self.init(
        kind: .search,
        value: record.value,
        selection: rangeAfterPrefix(input, in: record.value),
        representsInput: false,
        preferredMatch: true,
      )
    case .chat:
      return nil
    }
  }
}

fileprivate func rangeAfterPrefix(_ prefix: String, in string: String) -> Range<String.Index>? {
  guard string.hasPrefix(prefix) else { return nil }
  let start = string.index(string.startIndex, offsetBy: prefix.count)
  return start..<string.endIndex
}