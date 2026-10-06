public protocol SpaceGridModelProviding {
  @MainActor
  var spaceGridModel: SpaceGridModel { get }
}