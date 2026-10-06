public enum HorizontalAlignment: Sendable, Equatable {
  case leading
  case center
  case trailing
}

extension HorizontalAlignment {
  public var flipped: HorizontalAlignment {
    switch self {
    case .leading:
      .trailing
    case .center:
      .center
    case .trailing:
      .leading
    }
  }
}