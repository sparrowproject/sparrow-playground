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