@MainActor
public final class Weak<T: AnyObject> {
  public init(_ value: T) {
    self.value = value
  }

  public private(set) weak var value: T?

  public func isDiscarded() -> Bool {
    value == nil
  }
}