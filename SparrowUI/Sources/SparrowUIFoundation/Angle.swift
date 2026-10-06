import Foundation

public enum Angle: Equatable {
  case zero
  case degrees(CGFloat)
  case radians(CGFloat)

  public var degrees: CGFloat {
    switch self {
    case .zero:
      0

    case .degrees(let value):
      value

    case .radians(let value):
      value * 180 / .pi
    }
  }

  public var radians: CGFloat {
    switch self {
    case .zero:
      0
    
    case .degrees(let value):
      value * .pi / 180

    case .radians(let value):
      value
    }
  }
}