import SparrowUICore

public struct IfLet<Value, ID, Content>: View where ID: Hashable, Content: View {
  public init(
    _ expression: @autoclosure @escaping () -> Value?,
    id: KeyPath<Value, ID>,
    content: @escaping (Value) -> Content
  ) {
    self.expression = expression
    self.id = id
    self.content = content
  }

  public init(
    _ expression: @autoclosure @escaping () -> Value?,
    _ content: @escaping (Value) -> Content,
  ) where Value: Identifiable, Value.ID == ID {
    self.init(expression(), id: \.id, content: content)
  }

  public var body: some View {
    Repeated(expression().flatMap { [$0] } ?? [], id: id) {
      content($0)
    }
  }

  private let expression: () -> Value?
  private let id: KeyPath<Value, ID>
  private let content: (Value) -> Content
}