import Foundation

public struct EdgeInsets: Sendable {
  public init(leading: CGFloat, trailing: CGFloat, top: CGFloat, bottom: CGFloat) {
    self.leading = leading
    self.trailing = trailing
    self.top = top
    self.bottom = bottom
  }

  public let leading: CGFloat
  public let trailing: CGFloat
  public let top: CGFloat
  public let bottom: CGFloat
}

extension EdgeInsets: Equatable {}

extension EdgeInsets {
  public static let zero = EdgeInsets(leading: 0, trailing: 0, top: 0, bottom: 0)
}

extension EdgeInsets {
  public init(uniform: CGFloat) {
    self.init(leading: uniform, trailing: uniform, top: uniform, bottom: uniform)
  }
}

extension EdgeInsets {
  public init(horizontal: CGFloat) {
    self.init(leading: horizontal, trailing: horizontal, top: 0, bottom: 0)
  }
}

extension EdgeInsets {
  public init(vertical: CGFloat) {
    self.init(leading: 0, trailing: 0, top: vertical, bottom: vertical)
  }
}

extension EdgeInsets {
  public init(edges: EdgeSet, value: CGFloat) {
    self.init(
      leading: edges.contains(.leading) || edges.contains(.horizontal) ? value : 0,
      trailing: edges.contains(.trailing) || edges.contains(.horizontal) ? value : 0,
      top: edges.contains(.top) || edges.contains(.vertical) ? value : 0,
      bottom: edges.contains(.bottom) || edges.contains(.vertical) ? value : 0,
    )
  }
}

extension EdgeInsets {
  public var totalHorizontal: CGFloat {
    leading + trailing
  }

  public var totalVertical: CGFloat {
    top + bottom
  }
}
