import SparrowUIFoundation

public struct Button<Label: View>: View {
  public init(action: @escaping () -> Void, label: @escaping (ButtonConfig) -> Label) {
    self.action = action
    self.label = label
    style = UnstyledButtonStyle()
    disabled = { false }
  }

  public init(action: @escaping () -> Void, label: @escaping () -> Label) {
    self.action = action
    self.label = { _ in label() }
    style = UnstyledButtonStyle()
    disabled = { false }
  }

  private init(
    action: @escaping () -> Void,
    label: @escaping (ButtonConfig) -> Label,
    style: any ButtonStyle,
    disabled: @escaping () -> Bool,
  ) {
    self.action = action
    self.label = label
    self.style = style
    self.disabled = disabled
  }

  public var body: some View {
    styledLabel
      .onPointerDown { event in
        event.handled = true
        config.isPressed = true
      }
      .onPointerUp { event in
        event.handled = false
        if config.isPressed {
          config.isPressed = false
          if !config.isDisabled {
            action()
          }
        }
      }
      .onPointerEntered {
        withAnimation {
          config.isPressed = wasPressed
        }
        config.isHovered = true
        wasPressed = false
      }
      .onPointerExited {
        wasPressed = config.isPressed
        withAnimation {
          config.isPressed = false
        }
        config.isHovered = false
      }
      .onChange(of: disabled()) {
        config.isDisabled = $0
      }
  }

  private let action: () -> Void
  private let label: (ButtonConfig) -> Label
  private let style: any ButtonStyle
  private let disabled: () -> Bool

  private var config = ButtonConfig()

  @State private var wasPressed = false

  private var styledLabel: some View {
    style.makeAnyBody(label: AnyView(label(config)), config: config)
  }
}

extension Button {
  public func buttonStyle<Style: ButtonStyle>(_ style: Style) -> Self {
    .init(
      action: action,
      label: label,
      style: style,
      disabled: disabled,
    )
  }

  public func disabled(_ disabled: @autoclosure @escaping () -> Bool = true) -> Self {
    .init(
      action: action,
      label: label,
      style: style,
      disabled: disabled,
    )
  }
}
