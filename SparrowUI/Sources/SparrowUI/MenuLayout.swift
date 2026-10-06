import Foundation

#if os(macOS)
import CoreGraphics
#endif

public struct MenuLayout: Equatable {
  public init(
    size: CGSize = .zero,
    itemRects: [MenuData.Item.ID: CGRect] = [:],
  ) {
    self.size = size
    self.itemRects = itemRects
  }

  public let size: CGSize
  public let itemRects: [MenuData.Item.ID: CGRect]
}