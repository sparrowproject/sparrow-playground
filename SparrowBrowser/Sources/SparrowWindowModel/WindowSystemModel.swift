import Observation
import SparrowProfileModel
import SparrowSpaces
import SparrowTabs
import Tagged

#if os(Windows)
import OrderedCollections
#endif

@Observable
@MainActor
public final class WindowSystemModel {
  public init() {}

  public var windows = [WindowID: WindowModel]() {
    didSet {
      browserWindows = windows.compactMapValues { model in
        model as? BrowserWindowModel
      }
    }
  }

  public private(set) var browserWindows = [WindowID: BrowserWindowModel]()

  #if os(Windows)
  /// Maintain the order of all overlapped windows:
  public var ordering = OrderedSet<WindowID>()
  #endif
}

extension WindowSystemModel {
  @discardableResult
  public func createBrowserWindow(forGroup groupID: TabGroupID = .newSpace(), inProfile profileID: ProfileID) -> BrowserWindowModel {
    let windowModel = BrowserWindowModel(
      id: .init(),
      profileID: profileID,
      groupID: groupID,
      scopedSpaces: [groupID],
    )
    windows[windowModel.id] = windowModel
    return windowModel
  }
}
