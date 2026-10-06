import SparrowToolbelt

public protocol BrowserWindowModelProviding {
  @MainActor
  var browserWindowModel: BrowserWindowModel { get }
}

extension LiveContainer where Self: BrowserWindowModelProviding {
  @MainActor
  var windowModel: WindowModel {
    browserWindowModel
  }
}

extension LiveContainer where Self: BrowserWindowModelProviding {
  @MainActor
  var windowID: WindowID {
    browserWindowModel.id
  }
}