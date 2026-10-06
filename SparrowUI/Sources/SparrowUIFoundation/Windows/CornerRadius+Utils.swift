#if os(Windows)
import WinUI

extension CornerRadius {
  public init(uniform value: Double) {
    self.init(
      topLeft: value,
      topRight: value,
      bottomRight: value,
      bottomLeft: value,
    )
  }
}

#endif