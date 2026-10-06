#if os(Windows)
import Foundation
import WindowsFoundation

extension CGPoint {
  public init(_ p: Point) {
    self.init(x: CGFloat(p.x), y: CGFloat(p.y))
  }
}

#endif