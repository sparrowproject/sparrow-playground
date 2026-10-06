import SparrowUIFoundation

/// The action of a `PopoverButton` is to present an associated popover.
/// It works like a toggle.
public struct PopoverButton<PopoverContent: View, Label: View>: View {
  public init(
    content: @MainActor @escaping (PopoverController) -> PopoverContent,
    label: @escaping (ButtonConfig) -> Label,
    primaryAction: @escaping () -> Void = { },
  ) {
    self.popoverContent = content
    self.label = label
    self.primaryAction = primaryAction
    buttonStyle = UnstyledButtonStyle()
    popoverPlacement = { .below(alignment: .leading) }
    popoverStyle = { .init() }
    popoverActivation = .pointerPress
    disabled = { false }
  }

  public init(
    content: @MainActor @escaping (PopoverController) -> PopoverContent,
    label: @escaping () -> Label,
    primaryAction: @escaping () -> Void = { },
  ) {
    self.popoverContent = content
    self.label = { _ in label() }
    self.primaryAction = primaryAction
    buttonStyle = UnstyledButtonStyle()
    popoverPlacement = { .below(alignment: .leading) }
    popoverStyle = { .init() }
    popoverActivation = .pointerPress
    disabled = { false }
  }

  public init(
    content: @MainActor @escaping () -> PopoverContent,
    label: @escaping (ButtonConfig) -> Label,
    primaryAction: @escaping () -> Void = { },
  ) {
    self.popoverContent = { _ in content() }
    self.label = label
    self.primaryAction = primaryAction
    buttonStyle = UnstyledButtonStyle()
    popoverPlacement = { .below(alignment: .leading) }
    popoverStyle = { .init() }
    popoverActivation = .pointerPress
    disabled = { false }
  }

  public init(
    content: @MainActor @escaping () -> PopoverContent,
    label: @escaping () -> Label,
    primaryAction: @escaping () -> Void = { },
  ) {
    self.popoverContent = { _ in content() }
    self.label = { _ in label() }
    self.primaryAction = primaryAction
    buttonStyle = UnstyledButtonStyle()
    popoverPlacement = { .below(alignment: .leading) }
    popoverStyle = { .init() }
    popoverActivation = .pointerPress
    disabled = { false }
  }

  private init(
    popoverContent: @MainActor @escaping (PopoverController) -> PopoverContent,
    label: @escaping (ButtonConfig) -> Label,
    buttonStyle: any ButtonStyle,
    primaryAction: @escaping () -> Void,
    popoverPlacement: @MainActor @escaping () -> PositionalAnchor.Placement,
    popoverStyle: @MainActor @escaping () -> PopoverStyle,
    popoverActivation: PopoverActivation,
    disabled: @escaping () -> Bool,
  ) {
    self.popoverContent = popoverContent
    self.label = label
    self.buttonStyle = buttonStyle
    self.primaryAction = primaryAction
    self.popoverPlacement = popoverPlacement
    self.popoverStyle = popoverStyle
    self.popoverActivation = popoverActivation
    self.disabled = disabled
  }

  public var body: some View {
    styledLabel
      .onPointerDown { event in
        event.handled = true
        if config.isPressed {
          config.isPressed = false
          print(">>> setting popoverIsPresented to false from onPointerDown")
          popoverIsPresented = false
        } else {
          config.isPressed = true
          if popoverActivation.supports(event) {
            popoverIsPresented = !config.isDisabled
            print(">>> popoverIsPresented set to \(popoverIsPresented) via onPointerDown, path 2")
          }
          if popoverActivation.contains(.pointerLongPress), longPressDetectionTask == nil {
            longPressDetectionTask = Task<Void, Never> {
              defer { longPressDetectionTask = nil }
              try? await Task.sleep(for: .seconds(Metrics.longPressDetectionInterval))
              guard !Task.isCancelled else { return }
              popoverIsPresented = !config.isDisabled
            }
          }
        }
      }
      .onPointerUp { event in
        longPressDetectionTask?.cancel()
        longPressDetectionTask = nil
        if popoverIsPresented == false {
          let wasPressed = config.isPressed
          config.isPressed = false
          if wasPressed, config.isHovered, !config.isDisabled {
            primaryAction()
          }
        }
      }
      .onPointerEntered {
        config.isHovered = true
        if popoverActivation.contains(.pointerLinger) {
          lingerDetectionTask?.cancel()
          lingerDetectionTask = Task<Void, Never> {
            defer { lingerDetectionTask = nil }
            try? await Task.sleep(for: .seconds(Metrics.lingerDetectionInterval))
            guard !Task.isCancelled else { return }
            popoverIsPresented = config.isHovered && !config.isDisabled
          }
        }
      }
      .onPointerExited {
        config.isHovered = false
        lingerDetectionTask?.cancel()
        lingerDetectionTask = nil
      }
      .onChange(
        of: popoverIsPresented,
        perform: {
          if !$0 {
            // Defer resetting `isPressed`. This way if the popover was dismissed through a click
            // on the button, the `onPointerDown` handling will not immediately re-show the popover.
            Task<Void, Never> {
              if config.isPressed, !popoverIsPresented {
                config.isPressed = false
              }
            }
          }
        }
      )
      .onChange(
        of: disabled(),
        perform: {
          config.isDisabled = $0
        }
      )
      .modifier(
        _PopoverModifier(
          isPresented: $popoverIsPresented,
          preferredAnchor: { .anchorTo(.bounds, place: popoverPlacement()) },
          style: popoverStyle,
          dismissOnPointerExit: popoverActivation.contains(.pointerLinger),
          content: { popoverContent(self) },
        )
      )
  }

  private enum Metrics {
    static var longPressDetectionInterval: Double { 0.5 } // Seconds
    static var lingerDetectionInterval: Double { 0.2 } // Seconds
  }

  private let popoverContent: @MainActor (PopoverController) -> PopoverContent
  private let popoverPlacement: @MainActor () -> PositionalAnchor.Placement
  private let popoverStyle: @MainActor () -> PopoverStyle
  private let popoverActivation: PopoverActivation
  private let label: (ButtonConfig) -> Label
  private let primaryAction: () -> Void
  private let buttonStyle: any ButtonStyle
  private let disabled: () -> Bool

  private var config = ButtonConfig()

  @State private var longPressDetectionTask: Task<Void, Never>?
  @State private var lingerDetectionTask: Task<Void, Never>?

  @State private var popoverIsPresented = false

  private var styledLabel: some View {
    buttonStyle.makeAnyBody(label: AnyView(label(config)), config: config)
  }
}

extension PopoverButton {
  public func buttonStyle<Style: ButtonStyle>(_ buttonStyle: Style) -> Self {
    .init(
      popoverContent: popoverContent,
      label: label,
      buttonStyle: buttonStyle,
      primaryAction: primaryAction,
      popoverPlacement: popoverPlacement,
      popoverStyle: popoverStyle,
      popoverActivation: popoverActivation,
      disabled: disabled,
    )
  }
}

extension PopoverButton: PopoverController {
  public func dismiss() {
    print(">>> PopoverButton.dismiss()")
    popoverIsPresented = false
  }
}

extension PopoverButton {
  public func popoverPlacement(_ placement: @autoclosure @MainActor @escaping () -> PositionalAnchor.Placement) -> Self {
    .init(
      popoverContent: popoverContent,
      label: label,
      buttonStyle: buttonStyle,
      primaryAction: primaryAction,
      popoverPlacement: placement,
      popoverStyle: popoverStyle,
      popoverActivation: popoverActivation,
      disabled: disabled,
    )
  }

  public func popoverStyle(_ popoverStyle: @autoclosure @MainActor @escaping () -> PopoverStyle) -> Self {
    .init(
      popoverContent: popoverContent,
      label: label,
      buttonStyle: buttonStyle,
      primaryAction: primaryAction,
      popoverPlacement: popoverPlacement,
      popoverStyle: popoverStyle,
      popoverActivation: popoverActivation,
      disabled: disabled,
    )
  }

  public func popoverActivation(_ activation: PopoverActivation) -> Self {
    .init(
      popoverContent: popoverContent,
      label: label,
      buttonStyle: buttonStyle,
      primaryAction: primaryAction,
      popoverPlacement: popoverPlacement,
      popoverStyle: popoverStyle,
      popoverActivation: activation,
      disabled: disabled,
    )
  }

  public func disabled(_ disabled: @autoclosure @escaping () -> Bool = false) -> Self {
    .init(
      popoverContent: popoverContent,
      label: label,
      buttonStyle: buttonStyle,
      primaryAction: primaryAction,
      popoverPlacement: popoverPlacement,
      popoverStyle: popoverStyle,
      popoverActivation: popoverActivation,
      disabled: disabled,
    )
  }
}

extension PopoverActivation {
  @MainActor
  fileprivate func supports(_ event: PointerEvent) -> Bool {
    if contains(.pointerPress), event.buttons == .left {
      return true
    }
    if contains(.pointerContextPress), event.buttons == .right {
      return true
    }
    // TODO: Add support for long presses!
    return false
  }
}
