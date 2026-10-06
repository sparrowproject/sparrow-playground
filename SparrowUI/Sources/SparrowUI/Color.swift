import SparrowUICore

@MainActor
public struct Color {
  public init(
    light: @autoclosure @MainActor @escaping () -> CoreColor,
    dark: @autoclosure @MainActor @escaping () -> CoreColor,
  ) {
    self.light = light
    self.dark = dark
  }

  public init(_ uniform: @autoclosure @MainActor @escaping () -> CoreColor) {
    light = uniform
    dark = uniform
  }

  public static let clear = Color(.clear)
  public static let white = Color(.white)
  public static let black = Color(.black)

  // Color values from https://developer.apple.com/design/human-interface-guidelines/color

  public static let red = Color(light: .init(hex: 0xFF383C), dark: .init(hex: 0xFF4245))
  public static let orange = Color(light: .init(hex: 0xFF8D28), dark: .init(hex: 0xFF9230))
  public static let yellow = Color(light: .init(hex: 0xFFCC00), dark: .init(hex: 0xFFD600))
  public static let green = Color(light: .init(hex: 0x34C759), dark: .init(hex: 0x30D158))
  public static let mint = Color(light: .init(hex: 0x00C8B3), dark: .init(hex: 0x00DAC3))
  public static let teal = Color(light: .init(hex: 0x00C3D0), dark: .init(hex: 0x00D2E0))
  public static let cyan = Color(light: .init(hex: 0x00C0E8), dark: .init(hex: 0x3CD3FE))
  public static let blue = Color(light: .init(hex: 0x0088FF), dark: .init(hex: 0x0091FF))
  public static let indigo = Color(light: .init(hex: 0x6155F5), dark: .init(hex: 0x6D7CFF))
  public static let purple = Color(light: .init(hex: 0xCB30E0), dark: .init(hex: 0xDB34F2))
  public static let pink = Color(light: .init(hex: 0xFF2D55), dark: .init(hex: 0xFF375F))
  public static let brown = Color(light: .init(hex: 0xAC7F5E), dark: .init(hex: 0xB78A66))

  public static let gray = Color(light: .init(hex: 0x8E8E93), dark: .init(hex: 0x8E8E93))
  public static let gray2 = Color(light: .init(hex: 0xAEAEB2), dark: .init(hex: 0x636366))
  public static let gray3 = Color(light: .init(hex: 0xC7C7CC), dark: .init(hex: 0x48484A))
  public static let gray4 = Color(light: .init(hex: 0xD1D1D6), dark: .init(hex: 0x3A3A3C))
  public static let gray5 = Color(light: .init(hex: 0xE5E5EA), dark: .init(hex: 0x2C2C2E))
  public static let gray6 = Color(light: .init(hex: 0xF2F2F7), dark: .init(hex: 0x1C1C1E))

  public static let primaryText = Color(light: .black, dark: .white)
  public static let primaryBackground = Color(light: .white, dark: .black)

  let light: () -> CoreColor
  let dark: () -> CoreColor
}

extension Color {
  public func opacity(_ opacity: @autoclosure @MainActor @escaping () -> Double) -> Color {
    .init(
      light: light().opacity(opacity()),
      dark: dark().opacity(opacity()),
    )
  }
}

extension Color {
  func resolved(with colorScheme: ColorScheme) -> CoreColor {
    switch colorScheme {
    case .light:
      light()
    case .dark:
      dark()
    }
  }
}

extension Color: View {
  public var body: some View {
    Rectangle()
      .fill(self)
  }
}

extension Color {
  public static func hex(_ value: UInt32) -> Color {
    .init(.init(hex: value))
  }
}