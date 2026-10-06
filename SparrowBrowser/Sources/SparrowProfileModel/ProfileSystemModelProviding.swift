public protocol ProfileSystemModelProviding {
  @MainActor
  var profileSystemModel: ProfileSystemModel { get }
}