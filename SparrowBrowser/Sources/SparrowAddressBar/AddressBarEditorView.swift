import Foundation
import SparrowDesignSystem
import SparrowSuggest
import SparrowUI
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
          text: $buffer,
          selection: $selection,
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
    .onChange(of: (buffer, selection), perform: { buffer, selection in
      defer {
        viewModel.content.editorValue = buffer
        viewModel.content.editorSelection = selection
      }
      print(">>> buffer changed: \"\(buffer)\", selection: \(selection)")
      guard buffer != viewModel.content.editorValue else { return }
      guard !buffer.isEmpty else {
        disableAutoSelect = false
        viewModel.suggestionsViewModel.clearSuggestions()
        return
      }
      // let isPrefix = viewModel.content.editorValue.hasPrefix(buffer)
      // guard !isPrefix else { return }
      if let oldSelection = viewModel.content.editorSelection, !oldSelection.isEmpty, viewModel.content.editorValue[..<oldSelection.lowerBound] == buffer {
        print(">>> disabling auto select")
        disableAutoSelect = true
        return
      }
      if viewModel.content.editorValue.hasPrefix(buffer) {
        print(">>> disabling auto select, buffer is prefix of editorValue")
        disableAutoSelect = true
      }
      print(">>> new buffer \"\(buffer)\", querying suggestions...")
      if buffer.hasPrefix(viewModel.content.editorValue) {
        print(">>> enabling auto select, editorValue is prefix of buffer")
        disableAutoSelect = false
      }
      viewModel.suggestionsViewModel.querySuggestions(for: buffer)
    })
    .onChange(of: viewModel.content.editorValue) {
      guard buffer != viewModel.content.editorValue else { return }
      print(">>> new editorValue, setting buffer: \"\(buffer)\", selection: nil")
      buffer = $0
      selection = nil
      disableAutoSelect = false
    }
    .onChange(of: viewModel.suggestionsViewModel.selectedSuggestionResult, perform: { result in
      if
        let value = result?.value,
        value != buffer.trimmingCharacters(in: .whitespacesAndNewlines)
      {
        print(">>> new suggest result, setting buffer: \"\(value)\", selection: \(result?.selection)")
        buffer = disableAutoSelect ? value.removing(result?.selection) : value
        selection = disableAutoSelect ? nil : result?.selection
      }
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
        selection = viewModel.content.editorSelection
        focused = true
        withAnimation {
          showEditorHighlight = true
        }
      }
    }
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
  private let action: (Action) -> Void

  @State private var buffer: String = ""
  @State private var selection: Range<String.Index>?
  @State private var showEditorHighlight = false
  @State private var layout = Layout.zero
  @State private var disableAutoSelect = false

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

  private func submit(_ result: SuggestQueryResult?) {
    guard let result else { return }
    viewModel.content.editorValue = result.value
    viewModel.mode = .placeholder
    focused = nil
    if let completion = AddressBarCompletion(result) {
      action(.submit(completion))
    }
  }

  private func handleTextEditorAction(_ action: TextEditor.Action) {
    switch action {
    case .submit:
      submit(viewModel.suggestionsViewModel.selectedSuggestionResult)
    case .cancel:
      viewModel.dismissEditor()
    case .focusNext:
      break // TODO: implement
    case .focusPrevious:
      break // TODO: implement
    case .moveUp:
      disableAutoSelect = false
      viewModel.suggestionsViewModel.moveSelectionUp()
    case .moveDown:
      disableAutoSelect = false
      viewModel.suggestionsViewModel.moveSelectionDown()
    }
  }
}

extension String {
  func removing(_ range: Range<String.Index>?) -> String {
    guard let range else { return self }
    return String(self[..<range.lowerBound] + self[range.upperBound...])
  }
}