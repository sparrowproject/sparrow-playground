import Observation

@MainActor
@Observable
public final class ButtonConfig {
  public internal(set) var isHovered = false
  public internal(set) var isPressed = false
  public internal(set) var isDisabled = false
}
