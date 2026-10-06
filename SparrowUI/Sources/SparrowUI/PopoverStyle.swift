@MainActor
public struct PopoverStyle: Sendable {
  public init(
    backdropStyle: @autoclosure @MainActor @escaping () -> WindowBackdropStyle = .default,
    borderStyle: @autoclosure @MainActor @escaping () -> WindowBorderStyle = .default,
    cornerStyle: @autoclosure @MainActor @escaping () -> WindowCornerStyle = .default,
  ) {
    self.backdropStyle = backdropStyle
    self.borderStyle = borderStyle
    self.cornerStyle = cornerStyle
  }

  public let backdropStyle: @MainActor () -> WindowBackdropStyle
  public let borderStyle: @MainActor () -> WindowBorderStyle
  public let cornerStyle: @MainActor () -> WindowCornerStyle
}