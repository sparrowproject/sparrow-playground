import Observation
import SparrowTabs
import SparrowUIFoundation

@Observable
@MainActor
public class WindowModel {
  init(id: WindowID, kind: WindowKind) {
    self.id = id
    self.kind = kind
  }

  public let id: WindowID
  public let kind: WindowKind

  // On macOS, the system takes care of remembering window presentation details.
  #if os(Windows)
  public var frame: DisplayRect?
  #endif
}

extension WindowModel {
  public var isIncognito: Bool {
    if let browserWindowModel = self as? BrowserWindowModel {
      browserWindowModel.profileID.isIncognito
    } else {
      false
    }
  }
}