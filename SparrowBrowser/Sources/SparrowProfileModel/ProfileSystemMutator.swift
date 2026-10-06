import SparrowToolbelt

@MainActor
public protocol ProfileSystemMutator: Sendable {
  @discardableResult
  func addProfile(
    id: ProfileID,
    index: Int,
    title: String,
  ) -> ProfileModel

  func commit()
}

final class DefaultProfileSystemMutator: ProfileSystemMutator {
  init(model: ProfileSystemModel) {
    self.model = model
  }

  @discardableResult
  func addProfile(
    id: ProfileID,
    index: Int,
    title: String,
  ) -> ProfileModel {
    let profileModel = ProfileModel(
      id: id,
      index: index,
      title: title,
    )
    provisionalProfiles.append(profileModel)
    return profileModel
  }

  func commit() {
    // Perform some sanity checks. Make sure the profile ID and indices are unique.
    for profile in provisionalProfiles {
      if profile.index < 0 {
        print(">>> invalid profile index!")
        continue
      }
      if model.normalProfiles.values.contains(where: {
        $0.id == profile.id || $0.index == profile.index
      }) {
        print(">>> profile id or index already in use!")
        continue
      }
      model.normalProfiles[profile.id] = profile
    }
  }

  private let model: ProfileSystemModel
  private var provisionalProfiles = [ProfileModel]()
}