#if os(Windows)
import Foundation
import WindowsFoundation

extension Size {
  public init(_ s: CGSize) {
    self.init(width: Float(s.width), height: Float(s.height))
  }
}

#endif