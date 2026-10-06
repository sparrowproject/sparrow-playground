import Observation

@Observable
@MainActor
public final class SuggestQueryModel {
  public enum Status: Sendable, Equatable {
    case pending
    case done
  }

  public let input: String
  public internal(set) var status = Status.pending
  public internal(set) var completions = [String]()

  init(input: String) {
    self.input = input
  }
}