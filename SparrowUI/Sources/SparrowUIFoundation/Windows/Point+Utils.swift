#if os(Windows)
import Foundation
import WindowsFoundation

extension Point {
  public init(_ p: CGPoint) {
    self.init(x: Float(p.x), y: Float(p.y))
  }
}

#endif