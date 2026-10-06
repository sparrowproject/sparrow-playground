#if os(Windows)
import UWP

extension RectInt32 {
  public static var zero: RectInt32 {
    .init(x: 0, y: 0, width: 0, height: 0)
  }

  public var area: Int32 {
    width * height
  }

  public func intersection(_ other: RectInt32) -> RectInt32? {
    let x1 = max(x, other.x)
    let y1 = max(y, other.y)
    let x2 = min(x + width, other.x + other.width)
    let y2 = min(y + height, other.y + other.height)

    let intersectionWidth = x2 - x1
    let intersectionHeight = y2 - y1

    guard intersectionWidth > 0, intersectionHeight > 0 else {
      return nil
    }

    return .init(
      x: x1,
      y: y1,
      width: intersectionWidth,
      height: intersectionHeight
    )
  }
}

#endif