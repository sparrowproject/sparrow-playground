import Observation
import SparrowProfileModel
import SparrowTabs

@Observable
public final class BrowserWindowModel: WindowModel {
  public init(
    id: WindowID,
    profileID: ProfileID,
    groupID: TabGroupID,
    scratchSpace: TabGroupID?,
  ) {
    self.profileID = profileID
    self.groupID = groupID
    self.scratchSpace = scratchSpace
    super.init(id: id, kind: .browser)
  }

  public let profileID: ProfileID

  /// Identifies the selected space for the window. This group is of type `space:`.
  public var groupID: TabGroupID

  /// An optional "scratch" space scoped to the window. If the window is closed, then
  /// this group will be removed. `groupID` may reference either this group or one from
  /// the profile's `SpaceSystem.savedGroups`.
  public var scratchSpace: TabGroupID?
}
