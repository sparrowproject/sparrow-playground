#if os(Windows)
import UWP

extension PointInt32 {
  public static var zero: PointInt32 {
    .init(x: 0, y: 0)
  }
}

#endif