public enum Future<Value: Sendable>: Sendable {
  case value(Value?)
  case deferred(Task<Value?, Never>)
}

extension Future {
  nonisolated(nonsending)
  public var value: Value? {
    get async {
      switch self {
      case .value(let value):
        return value
      case .deferred(let task):
        return await task.value
      }
    }
  }
}