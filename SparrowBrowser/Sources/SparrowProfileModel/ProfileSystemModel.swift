import Observation
import OrderedCollections

@Observable
@MainActor
public final class ProfileSystemModel {
  public init() {}

  public internal(set) var normalProfiles = OrderedDictionary<ProfileID, ProfileModel>()
}

extension ProfileSystemModel {
  public func mutate() -> ProfileSystemMutator {
    DefaultProfileSystemMutator(model: self)
  }
}