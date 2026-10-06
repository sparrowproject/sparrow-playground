import Foundation

public struct SquircleGeometry {
  public enum Steps: Equatable {
    case fixed(Int) // Use this when animating between different corner radius values.
    case derived
  }

  public struct Corner {
    public init(from fromPoint: CGPoint, to toPoint: CGPoint, ending tangentAxis: Axis, steps: Steps) {
      let cornerSize = min(abs(toPoint.x - fromPoint.x), abs(toPoint.y - fromPoint.y))
      let geom = SquircleGeometry(cornerSize: cornerSize, steps: steps)

      let originX: CGFloat =
        switch tangentAxis {
        case .horizontal:
          toPoint.x
        case .vertical:
          fromPoint.x
        }

      let originY: CGFloat =
        switch tangentAxis {
        case .horizontal:
          fromPoint.y
        case .vertical:
          toPoint.y
        }
      
      let angles: (CGFloat, CGFloat) =
        switch tangentAxis {
        case .horizontal:
          if toPoint.x > fromPoint.x {
            if toPoint.y > fromPoint.y {
              (.pi, .pi / 2)
            } else {
              (-.pi, -.pi / 2)
            }
          } else {
            if toPoint.y > fromPoint.y {
              (0, .pi / 2)
            } else {
              (0, -.pi / 2)
            }
          }
        case .vertical:
          if toPoint.x > fromPoint.x {
            if toPoint.y > fromPoint.y {
              (-.pi / 2, 0)
            } else {
              (.pi / 2, 0)
            }
          } else {
            if toPoint.y > fromPoint.y {
              (-.pi / 2, -.pi)
            } else {
              (.pi / 2, .pi)
            }
          }
        }
      
      points = geom.cornerPoints(
        center: .init(x: originX, y: originY),
        start: .radians(angles.0),
        end: .radians(angles.1),
      )
    }

    let points: [CGPoint]
  }

  public init(cornerSize: CGFloat, steps: Steps) {
    self.cornerSize = cornerSize
    self.steps = switch steps {
      case .fixed(let value):
        value
      case .derived:
        max(4, min(32, Int(ceil(cornerSize / Metrics.desiredSegmentLength))))
      }
  }

  public static func cornerSizeForRoundedRect(withCornerRadius cornerRadius: CGFloat) -> CGFloat {
    let scale = (1 - 1 / sqrt(2)) / (1 - pow(2, -1 / Metrics.exponent))
    return cornerRadius * scale
  }

  public let cornerSize: CGFloat

  public func cornerPoints(
    center: CGPoint,
    start: Angle,
    end: Angle,
  ) -> [CGPoint] {
    (0...steps).map { i in
      let t = start.radians + (end.radians - start.radians) * CGFloat(i) / CGFloat(steps)
      let x = powSigned(cos(t), 2 / Metrics.exponent) * cornerSize
      let y = powSigned(sin(t), 2 / Metrics.exponent) * cornerSize
      return CGPoint(x: center.x + x, y: center.y + y)
    }
  }

  private enum Metrics {
    static let exponent: CGFloat = 3
    static let desiredSegmentLength: CGFloat = 2
  }

  private let steps: Int
}

private func powSigned(_ v: CGFloat, _ p: CGFloat) -> CGFloat {
  v.sign == .minus ? -pow(abs(v), p) : pow(v, p)
}