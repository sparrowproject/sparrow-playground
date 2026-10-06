import Foundation

public struct Gradient {
  public struct Stop {
    public init(color: Color, location: CGFloat) {
      self.color = color
      self.location = location
    }

    public let color: Color
    public let location: CGFloat
  }
}