import SparrowHistory
import SparrowToolbelt

@main
struct TypedHistoryTests {
  @MainActor
  static func main() {
    let history = Factory<TypedHistory>.makeDefaultInstance(dependencies: ())
    precondition(history.queryRecord(matching: "") == nil)
    precondition(history.queryRecord(matching: "missing") == nil)

    let first = TypedHistoryRecord(kind: .navigation, value: "example.com")
    let second = TypedHistoryRecord(kind: .search, value: "example query")
    let unicode = TypedHistoryRecord(kind: .chat, value: "🦅 café")
    history.storeRecord(first)
    history.storeRecord(second)
    history.storeRecord(unicode)
    precondition(Array(history.model.records.values) == [first, second, unicode])
    precondition(Array(history.model.records.keys) == [first.value, second.value, unicode.value])
    precondition(history.queryRecord(matching: "example") == second)
    precondition(history.queryRecord(matching: "example.") == first)
    precondition(history.queryRecord(matching: first.value) == first)
    precondition(history.queryRecord(matching: "example.com/extra") == nil)
    precondition(history.queryRecord(matching: "Example") == nil)
    precondition(history.queryRecord(matching: "🦅 ca") == unicode)
    precondition(history.queryRecord(matching: "") == unicode)

    history.storeRecord(first)
    precondition(Array(history.model.records.values) == [second, unicode, first])
    precondition(history.queryRecord(matching: "example") == first)
    let replacement = TypedHistoryRecord(kind: .chat, value: first.value)
    history.storeRecord(replacement)
    precondition(Array(history.model.records.values) == [second, unicode, replacement])
    precondition(history.model.records[first.value] == replacement)
    precondition(history.queryRecord(matching: first.value) == replacement)

    let readonly = Factory<TypedHistory>.makeReadonlyWrapper(source: history)
    precondition(readonly.model === history.model)
    readonly.storeRecord(second)
    precondition(readonly.queryRecord(matching: "example") == replacement)
    precondition(Array(history.model.records.values) == [second, unicode, replacement])

    let empty = TypedHistoryRecord(kind: .search, value: "")
    history.storeRecord(empty)
    precondition(history.queryRecord(matching: "") == empty)
    precondition(history.queryRecord(matching: "example") == replacement)

    let bounded = Factory<TypedHistory>.makeDefaultInstance(dependencies: ())
    for index in 0..<1000 {
      bounded.storeRecord(TypedHistoryRecord(kind: .search, value: "record-\(index)"))
    }
    precondition(bounded.model.records.count == 1000)
    let refreshed = TypedHistoryRecord(kind: .chat, value: "record-0")
    bounded.storeRecord(refreshed)
    precondition(bounded.model.records.count == 1000)
    precondition(bounded.model.records.values.last == refreshed)

    let newest = TypedHistoryRecord(kind: .navigation, value: "newest")
    bounded.storeRecord(newest)
    precondition(bounded.model.records.count == 1000)
    precondition(bounded.model.records.keys.first == "record-2")
    precondition(bounded.model.records["record-1"] == nil)
    precondition(bounded.queryRecord(matching: "record-1")?.value == "record-199")
    precondition(bounded.queryRecord(matching: "record-0") == refreshed)
    precondition(bounded.queryRecord(matching: "") == newest)

    for index in 0..<1000 {
      bounded.storeRecord(TypedHistoryRecord(kind: .search, value: "replacement-\(index)"))
    }
    precondition(bounded.model.records.count == 1000)
    precondition(bounded.queryRecord(matching: "record-") == nil)
    precondition(bounded.queryRecord(matching: "newest") == nil)

    let sharedPrefix = Factory<TypedHistory>.makeDefaultInstance(dependencies: ())
    sharedPrefix.storeRecord(empty)
    sharedPrefix.storeRecord(TypedHistoryRecord(kind: .search, value: "shared"))
    let longer = TypedHistoryRecord(kind: .navigation, value: "shared/path")
    sharedPrefix.storeRecord(longer)
    for index in 0..<1000 {
      sharedPrefix.storeRecord(TypedHistoryRecord(kind: .search, value: "filler-\(index)"))
      if index == 998 {
        precondition(sharedPrefix.queryRecord(matching: "shared") == longer)
        precondition(sharedPrefix.model.records["shared"] == nil)
      }
    }
    precondition(sharedPrefix.queryRecord(matching: "shared") == nil)
    precondition(sharedPrefix.queryRecord(matching: "")?.value == "filler-999")
  }
}
