import SparrowToolbelt

@MainActor
public protocol TypedHistory {
  var model: TypedHistoryModel { get }

  func storeRecord(_: TypedHistoryRecord)
  func queryRecord(matching: String) -> TypedHistoryRecord?
}

public protocol TypedHistoryProviding {
  @MainActor
  var typedHistory: TypedHistory { get }
}

public typealias TypedHistoryDependencies
  = Any

extension Factory where Interface == TypedHistory {
  public static func makeDefaultInstance(dependencies: TypedHistoryDependencies) -> TypedHistory {
    DefaultTypedHistory(dependencies: dependencies)
  }

  public static func makeReadonlyWrapper(source: TypedHistory) -> TypedHistory {
    ReadonlyWrapperTypedHistory(source: source)
  }
}

final class DefaultTypedHistory: TypedHistory {
  init(dependencies: TypedHistoryDependencies) {
    self.dependencies = dependencies
  }

  let model = TypedHistoryModel()

  func storeRecord(_ record: TypedHistoryRecord) {
    model.records.removeValue(forKey: record.value)
    model.records[record.value] = record
    model.trie.insert(record)
  }

  func queryRecord(matching prefix: String) -> TypedHistoryRecord? {
    model.trie.record(matching: prefix)
  }

  private let dependencies: TypedHistoryDependencies
}

final class ReadonlyWrapperTypedHistory: TypedHistory {
  init(source: TypedHistory) {
    self.source = source
  }

  var model: TypedHistoryModel {
    source.model
  }

  func storeRecord(_: TypedHistoryRecord) {
    // Ignored
  }

  func queryRecord(matching prefix: String) -> TypedHistoryRecord? {
    source.queryRecord(matching: prefix)
  }

  private let source: TypedHistory
}
