public protocol WindowSystemModelProviding {
  @MainActor
  var windowSystemModel: WindowSystemModel { get }
}