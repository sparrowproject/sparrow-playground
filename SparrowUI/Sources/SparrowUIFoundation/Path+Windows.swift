#if os(Windows)
import Foundation
import Win2D

extension Path {
  public var canvasGeometry: CanvasGeometry {
    switch representation {
    case .rect(let rect):
      return try! CanvasGeometry.createRectangle(
        nil,
        Float(rect.minX),
        Float(rect.minY),
        Float(rect.width),
        Float(rect.height),
      )!

    case .roundedRect(let rect, let cornerRadius, let style):
      switch style {
      case .circular:
        return try! CanvasGeometry.createRoundedRectangle(
          nil,
          Float(rect.minX),
          Float(rect.minY),
          Float(rect.width),
          Float(rect.height),
          Float(cornerRadius),
          Float(cornerRadius),
        )!
      case .continuous:
        // Clamp corner size.
        let cornerSize = min(
          SquircleGeometry.cornerSizeForRoundedRect(withCornerRadius: cornerRadius),
          rect.width / 2,
          rect.height / 2,
        )
        // Use a fixed number of steps to support corner radius animation.
        let steps = SquircleGeometry.Steps.fixed(16)
        return Path { p in
          p.begin(at: CGPoint(x: rect.minX + cornerSize, y: rect.minY))

          p.line(to: CGPoint(x: rect.maxX - cornerSize, y: rect.minY))
          p.squircleCorner(to: .init(x: rect.maxX, y: rect.minY + cornerSize), ending: .vertical, steps: steps)

          p.line(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerSize))
          p.squircleCorner(to: .init(x: rect.maxX - cornerSize, y: rect.maxY), ending: .horizontal, steps: steps)

          p.line(to: CGPoint(x: rect.minX + cornerSize, y: rect.maxY))
          p.squircleCorner(to: .init(x: rect.minX, y: rect.maxY - cornerSize), ending: .vertical, steps: steps)

          p.line(to: CGPoint(x: rect.minX, y: rect.minY + cornerSize))
          p.squircleCorner(to: .init(x: rect.minX + cornerSize, y: rect.minY), ending: .horizontal, steps: steps)

          p.end()
        }.canvasGeometry
      }

    case .custom(let commands):
      var currentPoint = CGPoint.zero
      let builder = CanvasPathBuilder(nil)
      for command in commands {
        switch command {
        case .begin(let point):
          try! builder.beginFigure(Float(point.x), Float(point.y))
          currentPoint = point

        case .line(let point):
          try! builder.addLine(Float(point.x), Float(point.y))
          currentPoint = point

        case .squircleCorner(let point, let axis, let steps):
          SquircleGeometry.Corner(from: currentPoint, to: point, ending: axis, steps: steps)
            .points.dropFirst().forEach { try! builder.addLine(Float($0.x), Float($0.y)) }
          currentPoint = point

        case .end:
          try! builder.endFigure(.closed)
        }
      }
      return try! CanvasGeometry.createPath(builder)!
    }
  }
}

#endif