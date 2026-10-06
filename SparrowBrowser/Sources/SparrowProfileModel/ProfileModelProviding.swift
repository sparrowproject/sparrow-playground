public protocol ProfileModelProviding {
  @MainActor
  var profileModel: ProfileModel { get }
}