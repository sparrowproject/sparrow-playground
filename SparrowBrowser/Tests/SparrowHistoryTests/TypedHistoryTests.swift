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
    precondition(history.model.records == [first, second, unicode])
    precondition(history.queryRecord(matching: "example") == second)
    precondition(history.queryRecord(matching: "example.") == first)
    precondition(history.queryRecord(matching: first.value) == first)
    precondition(history.queryRecord(matching: "example.com/extra") == nil)
    precondition(history.queryRecord(matching: "Example") == nil)
    precondition(history.queryRecord(matching: "🦅 ca") == unicode)
    precondition(history.queryRecord(matching: "") == unicode)

    history.storeRecord(first)
    precondition(history.queryRecord(matching: "example") == first)
    let replacement = TypedHistoryRecord(kind: .chat, value: first.value)
    history.storeRecord(replacement)
    precondition(history.queryRecord(matching: first.value) == replacement)

    let readonly = Factory<TypedHistory>.makeReadonlyWrapper(source: history)
    precondition(readonly.model === history.model)
    readonly.storeRecord(second)
    precondition(readonly.queryRecord(matching: "example") == replacement)
    precondition(history.model.records.count == 5)

    let empty = TypedHistoryRecord(kind: .search, value: "")
    history.storeRecord(empty)
    precondition(history.queryRecord(matching: "") == empty)
    precondition(history.queryRecord(matching: "example") == replacement)
  }
}
