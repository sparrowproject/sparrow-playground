import Foundation

public struct PositionalAnchor: Sendable, Equatable {
  public enum Target: Sendable, Equatable {
    /// Specifies a point within the anchor view.
    case point(UnitPoint)

    /// Specifies the bounds of the anchor view.
    case bounds
  }

  public enum Placement: Sendable, Equatable {
    case above(alignment: HorizontalAlignment)
    case below(alignment: HorizontalAlignment)
    case before(alignment: VerticalAlignment)
    case after(alignment: VerticalAlignment)
  }

  public init(target: Target, placement: Placement) {
    self.target = target
    self.placement = placement
  }

  public let target: Target
  public let placement: Placement
}

extension PositionalAnchor {
  public static func anchorTo(_ target: Target, place placement: Placement) -> Self {
    .init(target: target, placement: placement)
  }
}

extension PositionalAnchor {
  /// The effective point within a rectangle that is being positioned relative to a target rectangle.
  public var originPoint: UnitPoint {
    switch placement {
    case .above(let alignment):
      switch alignment {
      case .leading:
        .init(x: 0, y: 1)
      case .center:
        .init(x: 0.5, y: 1)
      case .trailing:
        .init(x: 1, y: 1)
      }
    case .below(let alignment):
      switch alignment {
      case .leading:
        .init(x: 0, y: 0)
      case .center:
        .init(x: 0.5, y: 0)
      case .trailing:
        .init(x: 1, y: 0)
      }
    case .before(let alignment):
      switch alignment {
      case .top:
        .init(x: 1, y: 0)
      case .center:
        .init(x: 1, y: 0.5)
      case .bottom:
        .init(x: 1, y: 1)
      }
    case .after(let alignment):
      switch alignment {
      case .top:
        .init(x: 0, y: 0)
      case .center:
        .init(x: 0, y: 0.5)
      case .bottom:
        .init(x: 0, y: 1)
      }
    }
  }

  /// The effective point within a target rectangle that is used as the anchor point. The `origin` of
  /// the positioned rectangle will be placed at this target point.
  public var targetPoint: UnitPoint {
    switch target {
    case .point(let point):
      point
    case .bounds:
      switch placement {
      case .above(let alignment):
        switch alignment {
        case .leading:
          .init(x: 0, y: 0)
        case .center:
          .init(x: 0.5, y: 0)
        case .trailing:
          .init(x: 1, y: 0)
        }
      case .below(let alignment):
        switch alignment {
        case .leading:
          .init(x: 0, y: 1)
        case .center:
          .init(x: 0.5, y: 1)
        case .trailing:
          .init(x: 1, y: 1)
        }
      case .before(let alignment):
        switch alignment {
        case .top:
          .init(x: 0, y: 0)
        case .center:
          .init(x: 0, y: 0.5)
        case .bottom:
          .init(x: 0, y: 1)
        }
      case .after(let alignment):
        switch alignment {
        case .top:
          .init(x: 1, y: 0)
        case .center:
          .init(x: 1, y: 0.5)
        case .bottom:
          .init(x: 1, y: 1)
        }
      }
    }
  }
}

extension PositionalAnchor {
  public func computeRect(ofSize size: CGSize, relativeTo anchorRect: CGRect) -> CGRect {
    let targetPoint = targetPoint
    let anchorPoint = CGPoint(
      x: anchorRect.minX + anchorRect.width * targetPoint.x,
      y: anchorRect.minY + anchorRect.height * targetPoint.y,
    )

    let originPoint = originPoint
    let originOffset = CGPoint(
      x: size.width * originPoint.x,
      y: size.height * originPoint.y,
    )

    return CGRect(
      x: anchorPoint.x - originOffset.x,
      y: anchorPoint.y - originOffset.y,
      width: size.width,
      height: size.height,
    )
  }
}

#if os(Windows)
import WinUI

extension FlyoutPlacementMode {
  public static func from(_ anchor: PositionalAnchor) -> FlyoutPlacementMode {
    switch anchor.placement {
    case .above(let alignment):
      switch alignment {
      case .leading:
        .topEdgeAlignedLeft
      case .center:
        .top
      case .trailing:
        .topEdgeAlignedRight
      }
    case .below(let alignment):
      switch alignment {
      case .leading:
        .bottomEdgeAlignedLeft
      case .center:
        .bottom
      case .trailing:
        .bottomEdgeAlignedRight
      }
    case .before(let alignment):
      switch alignment {
      case .top:
        .leftEdgeAlignedTop
      case .center:
        .left
      case .bottom:
        .leftEdgeAlignedBottom
      }
    case .after(let alignment):
      switch alignment {
      case .top:
        .rightEdgeAlignedTop
      case .center:
        .right
      case .bottom:
        .rightEdgeAlignedBottom
      }
    }
  }
}
#endif