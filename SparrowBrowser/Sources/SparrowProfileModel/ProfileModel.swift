import Observation

@Observable
@MainActor
public final class ProfileModel {
  public init(id: ProfileID, index: Int, title: String) {
    self.id = id
    self.index = index
    self.title = title
  }

  /// A globally unique identifier for the profile.
  public let id: ProfileID

  /// A local storage index (a small number) used to name the directory
  /// containing the profiles data.
  public let index: Int

  /// The user visible title for the profile.
  public var title: String
}