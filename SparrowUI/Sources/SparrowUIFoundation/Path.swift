import Foundation

public struct Path: Equatable {
  public init(_ callback: (inout PathBuilder) -> Void) {
    var path = PathBuilder()
    callback(&path)
    representation = .custom(path.commands)
  }

  public init(rect: CGRect) {
    representation = .rect(rect)
  }

  public init(roundedRect rect: CGRect, cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous) {
    representation = .roundedRect(rect, cornerRadius: cornerRadius, style: style)
  }

  enum Command: Equatable {
    case begin(at: CGPoint)
    case line(to: CGPoint)
    case squircleCorner(to: CGPoint, ending: Axis, steps: SquircleGeometry.Steps)
    case end
    // TODO: add more
  }

  enum Representation: Equatable {
    case rect(CGRect)
    case roundedRect(CGRect, cornerRadius: CGFloat, style: RoundedCornerStyle)
    case custom([Command])
  }

  let representation: Representation
}