import SparrowUI

@MainActor
public enum StandardColors {
  public static let hoverBackground = Color(light: .black.opacity(0.1), dark: .white.opacity(0.3))
  public static let shadow = Color(light: .black.opacity(0.15), dark: .white.opacity(0.05))
  public static let border = Color.primaryText.opacity(0.2)
  public static let highlight = Color.blue.opacity(0.5)
  public static let highlightShadow = Color.blue.opacity(0.4)
}