import Foundation
import SparrowToolbelt
import Tagged

public typealias TabID = Tagged<TabModel, UUID>

extension TabID {
  public static let invalid = TabID(.zero)

  public var nilIfInvalid: TabID? {
    if self == .invalid {
      nil
    } else {
      self
    }
  }
}