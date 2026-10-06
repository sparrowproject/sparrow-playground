import Foundation

public struct CoreShadow: Sendable, Equatable {
  public init(
    color: CoreColor,
    radius: CGFloat,
    x: CGFloat,
    y: CGFloat,
  ) {
    self.color = color
    self.radius = radius
    self.x = x
    self.y = y
  }

  public let color: CoreColor
  public let radius: CGFloat
  public let x: CGFloat
  public let y: CGFloat
}