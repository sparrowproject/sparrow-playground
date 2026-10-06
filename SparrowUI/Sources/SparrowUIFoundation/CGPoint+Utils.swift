import Foundation

extension CGPoint {
  public func distance(to point: CGPoint) -> CGFloat {
    hypot(point.x - x, point.y - y)
  }

  public func isInsideTriangleWithVertices(
    _ a: CGPoint,
    _ b: CGPoint,
    _ c: CGPoint,
  ) -> Bool {
    func signedArea(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
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