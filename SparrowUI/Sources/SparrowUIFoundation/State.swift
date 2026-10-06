import Observation

@MainActor
@propertyWrapper
public struct State<Value> {
  public init(wrappedValue: Value) {
    _valueContainer = .init(value: wrappedValue)
  }

  public var wrappedValue: Value {
    get { _valueContainer.value }
    nonmutating set { _valueContainer.value = newValue }
  }

  public var projectedValue: Binding<Value> {
    .init(
      get: {
        _valueContainer.value
      },
      set: {
        _valueContainer.value = $0
      }
    )
  }

  @Observable
  final class ValueContainer {
    init(value: Value) {
      self.value = value
    }
    var value: Value
  }

  private var _valueContainer: ValueContainer
}
