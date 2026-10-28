import Observation

@Observable
public final class ObservableValue<Value> {
  public init(_ value: Value) {
    self.value = value
  }

  public var value: Value
}