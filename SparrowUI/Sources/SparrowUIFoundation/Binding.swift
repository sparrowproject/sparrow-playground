import Observation

@propertyWrapper
public struct Binding<Value> {
  public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
    self.get = get
    self.set = set
  }

  public let get: () -> Value
  public let set: (Value) -> Void

  public var wrappedValue: Value {
    get { get() }
    nonmutating set { set(newValue) }
  }
}

extension Binding {
  public static func constant(_ value: Value) -> Self {
    .init(get: { value }, set: { _ in })
  }
}

extension Binding {
  /// Returns a `Binding` for a member of an `Observable` type.
  public static func binding<Member, ObjectType>(
    for member: Member,
    on object: ObjectType,
  ) -> Self where ObjectType: AnyObject & Observable, Member: ReferenceWritableKeyPath<ObjectType, Value> {
    .init(
      get: {
        object[keyPath: member]
      },
      set: {
        object[keyPath: member] = $0
      },
    )
  }
}