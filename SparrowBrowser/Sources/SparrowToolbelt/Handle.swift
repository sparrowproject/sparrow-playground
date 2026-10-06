import Observation

/// An observable wrapper around a value. This can be used to inject
/// mutable values that subsystems can observe.
@Observable @MainActor @dynamicMemberLookup
public final class Handle<Value> {
  public init(_ value: Value) {
    self.value = value
  }

  public subscript<Member>(dynamicMember keyPath: KeyPath<Value, Member>) -> Member {
    value[keyPath: keyPath]
  }

  public var value: Value
}