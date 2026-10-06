#if os(Windows)
import Foundation
import WindowsFoundation

extension CGSize {
  public init(_ s: Size) {
    self.init(width: CGFloat(s.width), height: CGFloat(s.height))
  }
}

#endif