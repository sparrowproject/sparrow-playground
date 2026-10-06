import Foundation

extension CGSize {
  public func contains(_ point: CGPoint) -> Bool {
    point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
  }
}
