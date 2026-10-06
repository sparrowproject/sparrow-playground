import Foundation
import SparrowUI

public struct StandardButtonStyle: ButtonStyle {
  public init(
    cornerRadius: @autoclosure @escaping @MainActor () -> CGFloat = StandardMetrics.buttonCornerRadius,
    backgroundColor: @autoclosure @escaping @MainActor () -> Color = StandardColors.hoverBackground,
  ) {
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
  } 

  public func makeBody(label: AnyView, config: ButtonConfig) -> some View {
    Group {
      RoundedRectangle(cornerRadius: cornerRadius())
        .fill(buttonBackground(for: config))
      label
        .alignment(.center)
    }
    .opacity(buttonOpacity(for: config))
  }

  private let cornerRadius: @MainActor () -> CGFloat
  private let backgroundColor: @MainActor () -> Color

  private func buttonBackground(for config: ButtonConfig) -> Color {
    (config.isHovered && !config.isDisabled) ? backgroundColor() : .clear
  }

  private func buttonOpacity(for config: ButtonConfig) -> CGFloat {
    if config.isDisabled {
      0.3
    } else if config.isPressed {
      0.6
    } else if config.isHovered {
      1
    } else {
      0.8
    }
  }
}

extension ButtonStyle where Self == StandardButtonStyle {
  public static var standard: StandardButtonStyle { .init() }
}