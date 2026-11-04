import Observation
import SparrowToolbelt
import SparrowUIFoundation

@Observable
@MainActor
public final class SuggestQueryModel {
  public enum Status: Sendable, Equatable {
    case pending
    case done
  }

  public let input: String
  public internal(set) var status = Status.pending
  public internal(set) var completions = [SuggestQueryResult]()

  init(input: String) {
    self.input = input
  }
}

extension SuggestQueryModel {
  /// Generate a transitional model. This model preserves the previous search results, if
  /// they still make sense, while the new results are being fetched. This is useful for
  /// minimizing suggestions flicker while typing.
  public func transitionalModel(from previous: SuggestQueryModel?) -> SuggestQueryModel {
    guard let previous, status != .done else { return self }

    guard input.hasPrefix(previous.input) else { return self }

    // This solution is dependent on the implementation of `MergedSuggestQuery`.

    // Preserve non-preferred results.
    let previousNonPreferredResults = previous.completions.filter({
      !$0.preferredMatch
    })

    let model = SuggestQueryModel(input: input)
    model.completions = completions

    let insertionIndex = max(0, (completions.last?.isChat == true) ? completions.count - 1 : completions.count)
    model.completions.insert(
      contentsOf: previousNonPreferredResults,
      at: insertionIndex,
    )
    return model
  }
}