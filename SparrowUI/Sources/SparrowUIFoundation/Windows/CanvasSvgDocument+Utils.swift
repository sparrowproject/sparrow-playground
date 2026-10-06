#if os(Windows)
import Win2D
import WindowsFoundation

extension CanvasSvgDocument {
  public var intrinsicSize: Size? {
    var widthUnits = CanvasSvgLengthUnits.number
    var heightUnits = CanvasSvgLengthUnits.number

    guard
      let width = try? root.getLengthAttribute("width", &widthUnits),
      let height = try? root.getLengthAttribute("height", &heightUnits),
      widthUnits == .number,
      heightUnits == .number,
      width > 0,
      height > 0
    else {
      return nil
    }

    return .init(width: width, height: height)
  }
}

#endif