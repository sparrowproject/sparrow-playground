import Observation

@Observable
@MainActor
public final class TypedHistoryModel {
  public internal(set) var records = [TypedHistoryRecord]()
}
