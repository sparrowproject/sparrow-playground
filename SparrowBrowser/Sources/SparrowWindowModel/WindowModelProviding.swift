public protocol WindowModelProviding {
  @MainActor
  var windowModel: WindowModel { get }
}