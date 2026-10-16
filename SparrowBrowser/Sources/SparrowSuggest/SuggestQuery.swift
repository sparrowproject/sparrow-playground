@MainActor
public protocol SuggestQuery: AnyObject {
  var model: SuggestQueryModel { get }

  func cancel()
}