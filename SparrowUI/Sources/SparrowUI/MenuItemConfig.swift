import Foundation
import Observation

@MainActor
@Observable
public final class MenuItemConfig {
  public internal(set) var isHovered = false
  public internal(set) var isActivated = false

  // var size = CGSize.zero
}
