import SparrowToolbelt

public protocol ProfileIDProviding {
  @MainActor
  var profileID: ProfileID { get }
}

extension LiveContainer where Self: ProfileModelProviding {
  @MainActor
  public var profileID: ProfileID {
    profileModel.id
  }
}