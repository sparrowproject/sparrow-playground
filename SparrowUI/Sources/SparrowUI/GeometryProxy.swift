import Foundation
import Observation

@MainActor
@Observable
public final class GeometryProxy {
  public var width: CGFloat {
    if let _width {
      _width()
    } else {
      .zero
    }
  }

  public var height: CGFloat {
    if let _height {
      _height()
    } else {
      .zero
    }
  }

  var _width: (@MainActor () -> CGFloat)?
  var _height: (@MainActor () -> CGFloat)?
}

extension GeometryProxy {
  public var size: CGSize {
    .init(width: width, height: height)
  }
}