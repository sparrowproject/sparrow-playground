import Foundation

// These types map to how the OS represents position on screen.
#if os(macOS)
public typealias DisplayUnit = CGFloat
public typealias DisplayPoint = CGPoint
public typealias DisplaySize = CGSize
public typealias DisplayRect = CGRect
#elseif os(Windows)
import UWP
public typealias DisplayUnit = Int32
public typealias DisplayPoint = UWP.PointInt32
public typealias DisplaySize = UWP.SizeInt32
public typealias DisplayRect = UWP.RectInt32

extension DisplayPoint {
  public func distance(to point: DisplayPoint) -> DisplayUnit {
    DisplayUnit(hypot(Double(point.x - x), Double(point.y - y)))
  }

  // TODO: Find a way to share this code with the CGPoint extension.
  public func isInsideTriangleWithVertices(
    _ a: DisplayPoint,
    _ b: DisplayPoint,
    _ c: DisplayPoint,
  ) -> Bool {
    func signedArea(_ p1: DisplayPoint, _ p2: DisplayPoint, _ p3: DisplayPoint) -> DisplayUnit {
      (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
    }

    let d1 = signedArea(self, a, b)
    let d2 = signedArea(self, b, c)
    let d3 = signedArea(self, c, a)

    let hasNegative = d1 < 0 || d2 < 0 || d3 < 0
    let hasPositive = d1 > 0 || d2 > 0 || d3 > 0

    return !(hasNegative && hasPositive)
  }
}

extension DisplayRect {
  public init(origin: DisplayPoint, size: DisplaySize) {
    self.init(x: origin.x, y: origin.y, width: size.width, height: size.height)
  }

  public var origin: DisplayPoint {
    .init(x: x, y: y)
  }

  public var size: DisplaySize {
    .init(width: width, height: height)
  }

  public var minX: DisplayUnit {
    x
  }

  public var minY: DisplayUnit {
    y
  }

  public var maxX: DisplayUnit {
    x + width
  }

  public var maxY: DisplayUnit {
    y + height
  }

  public var centerX: DisplayUnit {
    (minX + maxX) / 2
  }

  public var centerY: DisplayUnit {
    (minY + maxY) / 2
  }

  public var center: DisplayPoint {
    .init(x: centerX, y: centerY)
  }

  public func insetBy(dx: DisplayUnit, dy: DisplayUnit) -> DisplayRect {
    .init(
      x: x + dx,
      y: y + dy,
      width: width - 2 * dx,
      height: height - 2 * dy,
    )
  }

  public func contains(_ p: DisplayPoint) -> Bool {
    p.x >= minX && p.y >= minY && p.x < maxX && p.y < maxY
  }
}
#endif