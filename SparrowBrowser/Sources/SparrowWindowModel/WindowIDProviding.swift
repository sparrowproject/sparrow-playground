public protocol WindowIDProviding {
  @MainActor
  var windowID: WindowID { get }
}