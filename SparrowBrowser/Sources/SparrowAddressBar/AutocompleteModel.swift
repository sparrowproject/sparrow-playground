@MainActor
final class AutocompleteModel {
  enum Action {
    case updateEditor(String, selection: Range<String.Index>?)
    case querySuggestions(String)
    case clearSuggestions
  }

  init() {}

  func initializeEditorState(value: String, selection: Range<String.Index>?) {
    hasInitialEditorState = true
    editorString = value
    editorSelection = selection
  }

  func handleEditorChange(value: String, selection: Range<String.Index>?) -> [Action] {
    guard hasInitialEditorState else { return [] }

    let (value, selection) = Self.normalizeInput(value: value, selection: selection)
    guard value != editorString || selection != editorSelection else { return [] }

    // Observe if the user appears to have deleted a trailing selection.
    if
      selection == nil,
      editorString != value,
      editorString.hasPrefix(value),
      (editorSelection == nil ||
       editorSelection?.lowerBound == editorString.index(editorString.startIndex, offsetBy: value.count))
    {
      deletingFromTheEnd = true
    } else {
      deletingFromTheEnd = false
    }

    editorString = value
    editorSelection = selection

    // Avoid querying suggestions when the editor is just being updated to show the current suggestion.
    if editorString == suggestionString, editorSelection == suggestionSelection {
      return []
    }

    var actions = [Action]()

    // Handle the case of typing more of the autocomplete result.
    if
      !deletingFromTheEnd,
      editorSelection == nil,
      let suggestionString,
      suggestionString != editorString,
      suggestionString.hasPrefix(editorString)
    {
      editorString = suggestionString
      editorSelection = value.endIndex..<editorString.endIndex
      actions.append(.updateEditor(editorString, selection: editorSelection))
    }

    actions.append(.querySuggestions(value))

    return actions
  }

  func handleSuggestionChange(value: String?, selection: Range<String.Index>?) -> [Action] {
    guard hasInitialEditorState else { return [] }

    let (value, selection) = Self.normalizeInput(value: value, selection: selection)
    guard value != suggestionString || selection != suggestionSelection else { return [] }

    // Nothing to do if the editor already reflects these values.
    if editorString == value, editorSelection == selection {
      suggestionString = value
      suggestionSelection = selection
      return []
    }

    suggestionString = value
    suggestionSelection = selection

    guard let value else {
      return []
    }

    guard editorString != value else {
      return []
    }

    // // Take care to avoid stomping over the user who is deleting characters at the end and
    // // getting back suggestions for the new prefix.
    if deletingFromTheEnd {
      if
        value != editorString,
        value.hasPrefix(editorString),
        editorSelection == nil,
        let suggestionSelection,
        suggestionSelection.lowerBound == value.index(value.startIndex, offsetBy: editorString.count)
      {
        return []
      }
      deletingFromTheEnd = false
    }

    editorString = value
    editorSelection = selection

    return [.updateEditor(editorString, selection: editorSelection)]
  }

  private var hasInitialEditorState = false

  private var editorString: String = ""
  private var editorSelection: Range<String.Index>?

  private var suggestionString: String?
  private var suggestionSelection: Range<String.Index>?

  private var deletingFromTheEnd = false

  private static func normalizeInput(value: String, selection: Range<String.Index>?) -> (value: String, selection: Range<String.Index>?) {
    if selection?.lowerBound == value.endIndex && selection?.upperBound == value.endIndex {
      (value: value, selection: nil)
    } else {
      (value: value, selection: selection)
    }
  }

  private static func normalizeInput(value: String?, selection: Range<String.Index>?) -> (value: String?, selection: Range<String.Index>?) {
    if selection?.lowerBound == value?.endIndex && selection?.upperBound == value?.endIndex {
      (value: value, selection: nil)
    } else {
      (value: value, selection: selection)
    }
  }
}