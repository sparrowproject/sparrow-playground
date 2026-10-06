#if os(Windows)
import WinUI

extension Thickness {
  public init(uniform value: Double) {
    self.init(
      left: value,
      top: value,
      right: value,
      bottom: value,
    )
  }
}

#endif