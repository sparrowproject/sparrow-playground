#if os(Windows)
import Foundation
import WindowsFoundation

extension CGRect {
  public init(_ r: Rect) {
    self.init(
      x: CGFloat(r.x),
      y: CGFloat(r.y),
      width: CGFloat(r.width),
      height: CGFloat(r.height),
    )
  }
}

#endif