@MainActor
public protocol ButtonStyle {
  associatedtype Body: View

  func makeBody(label: AnyView, config: ButtonConfig) -> Body
}

extension ButtonStyle {
  func makeAnyBody(label: AnyView, config: ButtonConfig) -> AnyView {
    AnyView(makeBody(label: label, config: config))
  }
}

struct UnstyledButtonStyle: ButtonStyle {
  public func makeBody(label: AnyView, config _: ButtonConfig) -> some View {
    label
  }
}
