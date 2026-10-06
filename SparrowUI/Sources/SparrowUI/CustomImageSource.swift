import SparrowUIFoundation

@MainActor
public protocol CustomImageSource {
  associatedtype Provider: ImageProvider

  var kind: String { get }
  func resolve(id: String) -> Provider?
}