import Foundation

public struct UnitPoint: Sendable, Equatable {
  public init(x: CGFloat, y: CGFloat) {
    self.x = x
    self.y = y
  }

  public let x: CGFloat
  public let y: CGFloat
}

extension UnitPoint {
  public static let zero = UnitPoint(x: 0, y: 0)

  public static let topLeading = UnitPoint(x: 0, y: 0)
  public static let top = UnitPoint(x: 0.5, y: 0)
  public static let topTrailing = UnitPoint(x: 1, y: 0)

  public static let leading = UnitPoint(x: 0, y: 0.5)
  public static let center = UnitPoint(x: 0.5, y: 0.5)
  public static let trailing = UnitPoint(x: 1, y: 0.5)

  public static let bottomLeading = UnitPoint(x: 0, y: 1)
  public static let bottom = UnitPoint(x: 0.5, y: 1)
  public static let bottomTrailing = UnitPoint(x: 1, y: 1)
}

extension CGPoint {
  public static func from(_ unitPoint: UnitPoint) -> CGPoint {
    .init(x: unitPoint.x, y: unitPoint.y)
  }
}

#if os(Windows)
import WindowsFoundation

extension Vector2 {
  public static func from(_ unitPoint: UnitPoint) -> Vector2 {
    .init(x: Float(unitPoint.x), y: Float(unitPoint.y))
  }
}
#endif