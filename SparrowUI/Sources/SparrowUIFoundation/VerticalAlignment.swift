public enum VerticalAlignment: Sendable, Equatable {
  case top
  case center
  case bottom
}

extension VerticalAlignment {
  public var flipped: VerticalAlignment {
    switch self {
    case .top:
      .bottom
    case .center:
      .center
    case .bottom:
      .top
    }
  }
}