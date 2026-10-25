import Foundation
import SparrowHistory
@testable import SparrowStorage
import SparrowStorageBase
import SparrowToolbelt

@MainActor
func testTypedHistoryStore(_ root: URL) async throws {
  struct Paths: StoragePaths {
    let userDataDirectory: URL
  }
  @MainActor
  struct Dependencies: TypedHistoryStoreDependencies {
    let storagePaths: StoragePaths
    let typedHistory: TypedHistory
  }
  let directory = root.appendingPathComponent("typed-history")
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  let paths = Paths(userDataDirectory: directory)
  let history = Factory<TypedHistory>.makeDefaultInstance(dependencies: ())
  let store = TypedHistoryStore(dependencies: Dependencies(storagePaths: paths, typedHistory: history))
  await store.initialize()
  precondition(history.model.records.isEmpty)
  let first = TypedHistoryRecord(kind: .navigation, value: "example.com")
  let second = TypedHistoryRecord(kind: .search, value: "example query")
  let newest = TypedHistoryRecord(kind: .chat, value: "🦅 café")
  history.storeRecord(first)
  history.storeRecord(second)
  history.storeRecord(newest)
  let fileURL = directory.appendingPathComponent("typed-history.json")
  var observed = false
  for _ in 0..<200 {
    if let data = try? Data(contentsOf: fileURL),
       let records = try? JSONDecoder().decode([TypedHistoryRecord].self, from: data),
       records == [first, second, newest] {
      observed = true
      break
    }
    try await Task.sleep(for: .milliseconds(10))
  }
  precondition(observed, "Observation must persist changes before shutdown")
  history.storeRecord(first)
  // Shutdown must capture changes even before the observation task runs.
  _ = store.shutdown()

  let restored = Factory<TypedHistory>.makeDefaultInstance(dependencies: ())
  let reopened = TypedHistoryStore(dependencies: Dependencies(storagePaths: paths, typedHistory: restored))
  await reopened.initialize()
  precondition(Array(restored.model.records.values) == [second, newest, first])
  precondition(restored.queryRecord(matching: "example") == first)
  precondition(restored.queryRecord(matching: "🦅") == newest)
  let readonly = Factory<TypedHistory>.makeReadonlyWrapper(source: restored)
  readonly.storeRecord(TypedHistoryRecord(kind: .search, value: "private query"))
  _ = reopened.shutdown()
  let saved = try JSONDecoder().decode([TypedHistoryRecord].self, from: Data(contentsOf: directory.appendingPathComponent("typed-history.json")))
  precondition(saved == [second, newest, first])

  try Data("invalid JSON".utf8).write(to: directory.appendingPathComponent("typed-history.json"))
  let empty = Factory<TypedHistory>.makeDefaultInstance(dependencies: ())
  let corrupt = TypedHistoryStore(dependencies: Dependencies(storagePaths: paths, typedHistory: empty))
  await corrupt.initialize()
  precondition(empty.model.records.isEmpty)
  _ = corrupt.shutdown()
}
