#if os(macOS)
import AppKit

public typealias ImageRef = NSImage

#elseif os(Windows)
import Foundation
@preconcurrency import Win2D

public enum ImageRef: Sendable, Equatable {
  case bitmap(CanvasBitmap)
  case svg(CanvasSvgDocument)
}

extension ImageRef {
  public var size: CGSize? {
    switch self {
    case .bitmap(let bitmap):
      .init(bitmap.size)
    case .svg(let svg):
      svg.intrinsicSize.flatMap { CGSize($0) }
    }
  }
}

#endif