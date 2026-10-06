import SparrowUI
import SparrowUIFoundation

public final class SparrowCommand: Command {
  public enum ID: Int {
    case closeOtherTabs
    case closeTab
    case closeTabsAfter
    case closeWindow
    // case copy
    // case cut
    case duplicateTab
    case openLocation
    case muteTab
    case newTab
    case newIncognitoWindow
    case newTabAfter
    case newWindow
    // case paste
    case pinTab
    case quit
    case reloadTab
    case toggleTabMode
    case unmuteTab
    case unpinTab
    case goBack
    case goForward
    case selectNextTab
    case selectPreviousTab
    case selectTabAt0
    case selectTabAt1
    case selectTabAt2
    case selectTabAt3
    case selectTabAt4
    case selectTabAt5
    case selectTabAt6
    case selectTabAt7
    case selectTabAt8
    case selectTabAt9

    static func selectTabAt(index: Int) -> Self {
      switch index {
      case 0: .selectTabAt0
      case 1: .selectTabAt1
      case 2: .selectTabAt2
      case 3: .selectTabAt3
      case 4: .selectTabAt4
      case 5: .selectTabAt5
      case 6: .selectTabAt6
      case 7: .selectTabAt7
      case 8: .selectTabAt8
      case 9: .selectTabAt9
      default:
        preconditionFailure("Invalid index!")
      }
    }
  }

  init(
    id: ID,
    title: String,
    icon: ImageSource? = nil,
    keybinding: Keybinding? = nil,
  ) {
    self.id = id
    self.title = title
    self.icon = icon
    self.keybinding = keybinding
  }

  public let id: ID
  public var title: String
  public var icon: ImageSource?
  public var isHidden = false
  public var isEnabled = true
  public var isToggled = false
  public var keybinding: Keybinding?

  public static let browserReservedIDs = Set<SparrowCommand.ID>(
    [
      .closeTab,
      .closeWindow,
      .newIncognitoWindow,
      .newTab,
      .newWindow,
      .quit,
      .selectNextTab,
      .selectPreviousTab,
    ]
  )
}