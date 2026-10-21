import Foundation
import SparrowDesignSystem
import SparrowSuggest
import SparrowUI
import SparrowWeb

public struct AddressBarEditorView: View {
  public enum Action {
    case submit(URL)
    case dismissed
  }

  public init(viewModel: AddressBarViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      Group {
        // suggestionIcon(for: selectedSuggestionRow)
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
    // .readColorScheme(to: $colorScheme)
    .onChange(of: buffer, perform: { buffer in
      guard buffer != viewModel.content.editorValue else { return }
      viewModel.suggestionsViewModel.querySuggestions(for: buffer)
    })
    .onChange(of: viewModel.content.editorValue) {
      guard buffer != viewModel.content.editorValue else { return }
      buffer = $0
      selection = nil
    }
    .onChange(of: viewModel.suggestionsViewModel.selectedSuggestionResult, perform: { result in
      if let displayString = result?.displayString {
        guard buffer != displayString else { return }
        buffer = displayString
        viewModel.content.editorValue = displayString
        selection = nil
      }
    })
    .onChange(of: viewModel.suggestionsViewModel.suggestionResults, perform: { results in
      let index: Int? =
        if let results {
          results.map(\.displayString).firstIndex(of: buffer.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
          nil
        }
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
    // let rowHeight: CGFloat
    // let rowsOffsetY: [CGFloat]

    // func rowOffsetY(for index: Int) -> CGFloat {
    //   rowsOffsetY[safe: index] ?? 0
    // }

    static let zero = Layout(
      width: 0,
      height: 0,
      // rowHeight: 0,
      // rowsOffsetY: [],
    )
  }

  private let viewModel: AddressBarViewModel
  private let action: (Action) -> Void

  // @State private var initialized = false
  @State private var buffer: String = ""
  @State private var selection: Range<String.Index>?
  @State private var showEditorHighlight = false
  @State private var layout = Layout.zero
  // @State private var selectedSuggestionRow: Int? // Set by moveUp / moveDown events.
  // @State private var colorScheme = ColorScheme.light

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
      .navigation($0, displayString: buffer)
    }
  }

  private func computeLayout() -> Layout {
    let width = viewModel.placeholderSize.width

    // let numSuggestions = viewModel.suggestQueryModel?.completions.count ?? 0
    // let rowHeight = viewModel.placeholderSize.height
    // let height = CGFloat(numSuggestions + 1) * rowHeight

    // let rowsOffsetY: [CGFloat] = (0..<numSuggestions).map {
    //   viewModel.placeholderSize.height + CGFloat($0) * rowHeight
    // }

    return .init(
      width: width,
      height: viewModel.placeholderSize.height + suggestionsViewSize.height,
      // rowHeight: rowHeight,
      // rowsOffsetY: rowsOffsetY,
    )
  }

  private func submit(_ result: SuggestQueryResult?) {
    guard let result else { return }
    viewModel.content.editorValue = result.displayString
    viewModel.mode = .placeholder
    focused = nil
    if let url = result.url {
      action(.submit(url))
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
      viewModel.suggestionsViewModel.moveSelectionUp()
    case .moveDown:
      viewModel.suggestionsViewModel.moveSelectionDown()
    }
  }
}