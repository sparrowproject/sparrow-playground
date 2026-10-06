@MainActor
public protocol View {
  associatedtype Body: View

  var body: Self.Body { get }
}

extension View where Self.Body == Never {
  public var body: Never { fatalError("No Body") }
}

extension Never: View {
  public typealias Body = Never
}
