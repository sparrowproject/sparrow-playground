import Foundation

public struct CoreGradientStop: Sendable, Equatable {
  public init(color: CoreColor, location: CGFloat) {
    self.color = color
    self.location = location
  }

  public let color: CoreColor
  public let location: CGFloat
}