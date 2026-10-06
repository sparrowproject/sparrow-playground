@discardableResult
public func with<Value>(_ value: Value, perform: (inout Value) -> ()) -> Value {
  var value = value
  perform(&value)
  return value
}