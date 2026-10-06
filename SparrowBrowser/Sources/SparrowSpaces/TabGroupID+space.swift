import Foundation
import SparrowTabs

extension TabGroupID.Kind {
  public static let space: Self = .init(rawValue: "space")
}

extension TabGroupID {
  public static func newSpace() -> TabGroupID {
    .init(kind: .space, components: [UUID().uuidString])
  }
}