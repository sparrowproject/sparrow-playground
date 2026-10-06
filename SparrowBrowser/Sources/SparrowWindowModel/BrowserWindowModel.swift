import Observation
import OrderedCollections
import SparrowProfileModel
import SparrowTabs

@Observable
public final class BrowserWindowModel: WindowModel {
  public init(
    id: WindowID,
    profileID: ProfileID,
    groupID: TabGroupID,
    scopedSpaces: OrderedSet<TabGroupID>,
  ) {
    self.profileID = profileID
    self.groupID = groupID
    self.scopedSpaces = scopedSpaces
    super.init(id: id, kind: .browser)
  }

  public let profileID: ProfileID

  /// Identifies the selected space for the window. This group is of type `space:`.
  public var groupID: TabGroupID

  /// Represents the ordered set of spaces scoped to the window. If the window is
  /// closed, then these groups will be removed. `groupID` may reference one of
  /// these groups or one from the profile's `SpaceSystem.savedGroups`.
  public var scopedSpaces: OrderedSet<TabGroupID>
}
