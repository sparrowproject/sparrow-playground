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
  /// Generate a transitional model. This model preserves the previous results while the
  /// new results are being fetched, even if they no longer match. It also updates the
  /// selection of the first match if appropriate.
  public func transitionalModel(from previous: SuggestQueryModel?) -> SuggestQueryModel {
    guard let previous, status != .done else { return self }

    print(">>> transitionalModel for input: \"\(input)\", previous.input: \"\(previous.input)\"")

    if
      input.hasPrefix(previous.input),
      let firstCompletion = previous.completions.first,
      firstCompletion.selection != nil,
      firstCompletion.value.hasPrefix(input)
    {
      let model = SuggestQueryModel(input: input)
      model.completions = previous.completions
      model.completions[0] = with(firstCompletion) {
        $0.selection = input.endIndex ..< firstCompletion.value.endIndex
      }
      return model
    }

    print(">>> ... just using previous")

    return previous
  }
}