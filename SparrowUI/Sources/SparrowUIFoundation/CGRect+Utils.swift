import Foundation

#if os(macOS)
import CoreGraphics
#endif

extension CGRect {
  public var centerX: CGFloat {
    (minX + maxX) / 2
  }

  public var centerY: CGFloat {
    (minY + maxY) / 2
  }

  public var center: CGPoint {
    .init(x: centerX, y: centerY)
  }
  
  public var area: CGFloat {
    guard !isNull else { return 0 }
    return width * height
  }

  public func insetBy(_ insets: EdgeInsets) -> CGRect {
    .init(
      x: minX + insets.leading,
      y: minY + insets.top,
      width: width - insets.totalHorizontal,
      height: height - insets.totalVertical,
    )
  }

  public func outsetBy(_ insets: EdgeInsets) -> CGRect {
    .init(
      x: minX - insets.leading,
      y: minY - insets.top,
      width: width + insets.totalHorizontal,
      height: height + insets.totalVertical,
    )
  }

  public func offsetBy(_ delta: CGPoint) -> CGRect {
    .init(
      x: minX + delta.x,
      y: minY + delta.y,
      width: width,
      height: height,
    )
  }
}
