#if os(macOS)
import CoreGraphics
import struct SwiftUI.Path

extension Path {
  public var cgPath: CGPath {
    switch representation {
    case .rect(let rect):
      return .init(rect: rect, transform: nil)

    case .roundedRect(let rect, let cornerRadius, let style):
      // Use SwiftUI.Path for its glorious continuous style.
      return SwiftUI.Path(
        roundedRect: rect,
        cornerRadius: max(cornerRadius, .leastNonzeroMagnitude), // Avoid zero as it causes problems.
        style: style == .continuous ? .continuous : .circular,
      ).cgPath

    case .custom(let commands):
      let path = CGMutablePath()
      for command in commands {
        switch command {
        case .begin(let point):
          path.move(to: point)

        case .line(let point):
          path.addLine(to: point)

        case .squircleCorner(let point, let axis, let steps):
          SquircleGeometry.Corner(from: path.currentPoint, to: point, ending: axis, steps: steps)
            .points.dropFirst().forEach { path.addLine(to: $0) }
      
        case .end:
          path.closeSubpath()
        }
      }
      return path
    }
  }
}

#endif