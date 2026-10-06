import Foundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import Win2D
#endif

public struct TextLineBuilder {
  public init(text: String, font: Font) {
    #if os(macOS)
    let attrString = NSAttributedString(
      string: text,
      attributes: [
        .font: NSFont.from(font),
        NSAttributedString.Key(
          kCTForegroundColorFromContextAttributeName as String
        ): true,
      ]
    )
    line = CTLineCreateWithAttributedString(attrString)
    width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    #else

    let device = try! CanvasDevice.getSharedDevice()

    let format = CanvasTextFormat()
    format.fontFamily = font.family
    format.fontSize = Float(font.size)
    format.fontWeight = .init(weight: UInt16(font.weight.value))
    format.wordWrapping = .noWrap

    layout = CanvasTextLayout(
      device,
      text,
      format,
      0, // unconstrained width
      0, // unconstrained height
    )

    width = CGFloat(layout.layoutBounds.width)
    height = CGFloat(layout.layoutBounds.height)

    #endif
  }

  #if os(macOS)
  public let line: CTLine
  #elseif os(Windows)
  public let layout: CanvasTextLayout
  #endif

  public let width: CGFloat

  #if os(macOS)
  public private(set) var ascent: CGFloat = 0
  public private(set) var descent: CGFloat = 0
  public private(set) var leading: CGFloat = 0
  public var height: CGFloat {
    ascent + descent
  }
  #elseif os(Windows)
  public let height: CGFloat
  #endif
}
