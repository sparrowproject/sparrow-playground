import Foundation
import SparrowDesignSystem
import SparrowSuggest
import SparrowUI
import SparrowUICore
import SparrowWeb

public struct AddressBarEditorView: View {
  public enum Action {
    case submit(AddressBarCompletion)
    case dismissed
  }

  public init(viewModel: AddressBarViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      Group {
        SuggestionIconView(for: selectedSuggestionResult)
          .alignment(.leading)
          .padding(.leading, Metrics.padding)

        TextEditor(
          text: .init(get: { buffer }, set: { updateBuffer($0) }),
          selection: $bufferSelection,
          action: handleTextEditorAction,
        )
        .font(.system(size: 13, weight: .light))
        .contentAlignment(.leading)
        .contentPadding(.horizontal, Metrics.padding)
        .focused(when: $focused, equals: true)
        .padding(.leading, Metrics.padding + SuggestionIconView.Metrics.iconSize)
      }
      .height(viewModel.placeholderSize.height)

      suggestionRows
        .clipped()
        .offset(y: viewModel.placeholderSize.height)
    }
    .highlightBox(when: showEditorHighlight)
    .width(layout.width)
    .height(layout.height)
    .offset(x: viewModel.placeholderPositionInHost?.x ?? 0, y: viewModel.placeholderPositionInHost?.y ?? 0)
    .onChange(of: (buffer, bufferSelection), perform: { buffer, bufferSelection in
      apply(autocompleteModel.handleEditorChange(value: buffer, selection: bufferSelection))
    })
    .onChange(of: (viewModel.content.editorValue, viewModel.content.editorSelection)) { value, selection in
      if buffer != value {
        buffer = value
      }
      if bufferSelection != selection {
        bufferSelection = selection
      }
    }
    .onChange(of: viewModel.suggestionsViewModel.selectedSuggestionResult, perform: { result in
      apply(autocompleteModel.handleSuggestionChange(value: result?.value, selection: result?.selection))
    })
    .onChange(of: viewModel.suggestionsViewModel.suggestionResults, perform: { results in
      let index: Int? = results?.firstIndex(where: { $0.preferredMatch })
      if viewModel.suggestionsViewModel.selectedSuggestionRow != index {
        viewModel.suggestionsViewModel.selectedSuggestionRow = index
      }
    })
    .onChange(of: viewModel.mode) { mode in
      if mode == .placeholder {
        action(.dismissed)
      }
    }
    .onChange(of: computeLayout()) { layout in
      withAnimation {
        self.layout = layout
      }
    }
    .onAppear {
      // TODO: Can we avoid this Task somehow?
      Task {
        buffer = viewModel.content.editorValue
        bufferSelection = viewModel.content.editorSelection
        autocompleteModel.initializeEditorState(value: buffer, selection: bufferSelection)
        focused = true
        withAnimation {
          showEditorHighlight = true
        }
      }
    }
    .readScheduler(to: $scheduler)
  }

  private enum Metrics {
    static let padding = StandardMetrics.buttonCornerRadius
    static let iconSize: CGFloat = 13
  }

  private struct Layout {
    let width: CGFloat
    let height: CGFloat

    static let zero = Layout(
      width: 0,
      height: 0,
    )
  }

  private let viewModel: AddressBarViewModel
  private let autocompleteModel = AutocompleteModel()
  private let action: (Action) -> Void

  @State private var buffer: String = ""
  @State private var bufferSelection: Range<String.Index>?
  @State private var showEditorHighlight = false
  @State private var layout = Layout.zero
  @State private var scheduler: CoreScheduler?

  // TODO: Use a global focus state for this.
  @State private var focused: Bool?

  @State private var suggestionsViewSize = CGSize.zero

  private var suggestionRows: some View {
    SuggestionsView(viewModel: viewModel.suggestionsViewModel, rowHeight: viewModel.placeholderSize.height) {
      switch $0 {
      case .submit(let result):
        submit(result)
      }
    }
    .readSize(to: $suggestionsViewSize)
  }

  private var selectedSuggestionResult: SuggestQueryResult? {
    if let result = viewModel.suggestionsViewModel.selectedSuggestionResult {
      return result
    }
    return URL.fromUserInput(buffer, withSearchFallback: false).flatMap {
      .init(
        kind: .navigation($0),
        value: buffer,
        selection: nil,
        representsInput: false,
        preferredMatch: false,
      )
    }
  }

  private func computeLayout() -> Layout {
    let width = viewModel.placeholderSize.width

    return .init(
      width: width,
      height: viewModel.placeholderSize.height + suggestionsViewSize.height,
    )
  }

  private func updateBuffer(_ value: String) {
    guard buffer != value else { return }
    buffer = value

    // Update synchronously!
    let actions = autocompleteModel.handleEditorChange(value: buffer, selection: bufferSelection)
    apply(actions)
  }

  private func submit(_ result: SuggestQueryResult) {
    viewModel.content.editorValue = result.value
    viewModel.content.editorSelection = nil
    viewModel.mode = .placeholder
    focused = nil
    if let completion = AddressBarCompletion(result) {
      action(.submit(completion))
    }
  }

  private func apply(_ actions: [AutocompleteModel.Action]) {
    for action in actions {
      apply(action)
    }
  }

  private func apply(_ action: AutocompleteModel.Action) {
    switch action {
    case .updateEditor(let value, let selection):
      buffer = value
      bufferSelection = selection
    case .querySuggestions(let input):
      viewModel.suggestionsViewModel.querySuggestions(for: input)
    case .clearSuggestions:
      viewModel.suggestionsViewModel.clearSuggestions()
    }
  }

  private func handleTextEditorAction(_ action: TextEditor.Action) {
    switch action {
    case .submit:
      if let result = selectedSuggestionResult {
        submit(result)
      }
    case .cancel:
      viewModel.dismissEditor()
    case .focusNext:
      break // TODO: implement
    case .focusPrevious:
      break // TODO: implement
    case .moveUp:
      viewModel.suggestionsViewModel.moveSelectionUp()
    case .moveDown:
      viewModel.suggestionsViewModel.moveSelectionDown()
    }
  }
}