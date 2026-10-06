public func clamp<Value>(_ x: Value, _ lower: Value, _ upper: Value) -> Value where Value: Comparable {
  min(upper, max(lower, x))
}
