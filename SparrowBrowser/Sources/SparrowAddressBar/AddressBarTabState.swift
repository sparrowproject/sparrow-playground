import Observation
import SparrowTabs

@Observable
final class AddressBarTabState: TabAttribute {
  static let key = "AddressBarTabState"

  var editorHasFocus = false
  var placeholderString = ""
  var editorString = ""
  var editorSelection: Range<String.Index> = "".endIndex ..< "".endIndex
}

extension TabModel {
  var addressBarTabState: AddressBarTabState? {
    get { attribute(for: AddressBarTabState.self) }
    set { updateAttribute(newValue) }
  }
}