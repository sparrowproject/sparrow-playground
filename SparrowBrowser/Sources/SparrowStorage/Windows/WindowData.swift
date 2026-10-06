import OrderedCollections
import SparrowProfileModel
import SparrowTabs
import SparrowWindowModel

#if os(Windows)
import SparrowUIFoundation
#endif

struct WindowData: Codable, Sendable, Equatable {
  // #if os(Windows)
  // public enum PresentationStyle: Codable, Sendable, Equatable {
  //   case overlapped
  //   case fullscreen
  //   case minimized
  //   case maximized
  // }
  // #endif

  enum Kind: Codable, Sendable, Equatable {
    case browser(BrowserWindowData)
  }

  init(id: WindowID, kind: Kind) {
    self.id = id
    self.kind = kind
  }

  let id: WindowID
  let kind: Kind

  // On macOS, the system takes care of remembering window size & presentation details.
  #if os(Windows)
  var frame: DisplayRect?
  #endif

  // TODO: Move these fields to a new `SpaceSystem`.
  // public var persistsWhenClosed: Bool? = false
  // public var isHidden: Bool? = false
}

struct BrowserWindowData: Codable, Sendable, Equatable {
  let profileID: ProfileID
  let groupID: TabGroupID
  let scopedSpaces: OrderedSet<TabGroupID>
}

extension WindowData.Kind {
  @MainActor
  static func from(_ windowModel: WindowModel) -> Self {
    switch windowModel.kind {
    case .browser:
      let browserWindowModel = windowModel as! BrowserWindowModel
      return .browser(.init(
        profileID: browserWindowModel.profileID,
        groupID: browserWindowModel.groupID,
        scopedSpaces: browserWindowModel.scopedSpaces,
      ))
    }
  }
}

extension WindowData {
  @MainActor
  static func from(_ windowModel: WindowModel) -> Self {
    var data = WindowData(
      id: windowModel.id,
      kind: .from(windowModel),
    )
    #if os(Windows)
    data.frame = windowModel.frame
    #endif
    return data
  }

  @MainActor
  func makeWindowModel() -> WindowModel {
    switch kind {
    case .browser(let browserData):
      let browserWindowModel = BrowserWindowModel(
        id: id,
        profileID: browserData.profileID,
        groupID: browserData.groupID,
        scopedSpaces: browserData.scopedSpaces,
      )
      #if os(Windows)
      browserWindowModel.frame = frame
      #endif
      return browserWindowModel
    }
  }
}