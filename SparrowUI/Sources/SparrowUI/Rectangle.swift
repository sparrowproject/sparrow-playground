import Foundation
import SparrowUICore

public struct Rectangle: Shape {
  public init() {}

  public func path(in rect: CGRect) -> Path {
    .init(rect: rect)
  }
}
