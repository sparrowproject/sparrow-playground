#if os(Windows)
import Foundation
import WindowsFoundation

extension Rect {
  public init(_ r: CGRect) {
    self.init(
      x: Float(r.minX),
      y: Float(r.minY),
      width: Float(r.width),
      height: Float(r.height),
    )
  }
}

#endif