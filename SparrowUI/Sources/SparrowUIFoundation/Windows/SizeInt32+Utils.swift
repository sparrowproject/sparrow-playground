#if os(Windows)
import UWP

extension SizeInt32 {
  public static var zero: SizeInt32 {
    .init(width: 0, height: 0)
  }
}

#endif