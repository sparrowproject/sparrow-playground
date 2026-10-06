public enum WindowCornerStyle: Sendable, Equatable {
  case square
  case round(radius: Double)
}

extension WindowCornerStyle {
  public static var `default`: Self {
    .round(radius: 10)
  }

  public var radius: Double {
    switch self {
    case .square:
      0

    case .round(let radius):
      radius
    }
  }
}
