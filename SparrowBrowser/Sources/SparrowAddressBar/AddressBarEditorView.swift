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
        suggestionIcon(for: selectedSuggestionRow)

        TextEditor(
          text: $buffer,
          selection: $selection,
          action: handleTextEditorAction,
        )
        .font(.system(size: 13, weight: .light))
        .contentAlignment(.leading)
        .contentPadding(.horizontal, Metrics.padding)
        .focused(when: $focused, equals: true)
        .padding(.leading, Metrics.padding + Metrics.iconSize)
      }
      .height(viewModel.placeholderSize.height)

      suggestionRows
        .clipped()
    }
    .highlightBox(when: showEditorHighlight)
    .width(layout.width)
    .height(layout.height)
    .offset(x: viewModel.placeholderPositionInHost?.x ?? 0, y: viewModel.placeholderPositionInHost?.y ?? 0)
    .readColorScheme(to: $colorScheme)
    .onChange(of: buffer, perform: { buffer in
      guard buffer != viewModel.content.editorValue else { return }
      viewModel.querySuggestions(for: buffer)
    })
    .onChange(of: viewModel.content.editorValue) {
      guard buffer != viewModel.content.editorValue else { return }
      buffer = $0
      selection = nil
    }
    .onChange(of: selectedSuggestionRow, perform: { index in
      if let index {
        let suggestion = suggestion(at: index)?.displayString ?? ""
        guard buffer != suggestion else { return }
        buffer = suggestion
        viewModel.content.editorValue = suggestion
        selection = nil
      }
    })
    .onChange(of: viewModel.suggestQueryModel?.completions, perform: { completions in
      let index: Int? =
        if let completions {
          completions.map(\.displayString).firstIndex(of: buffer.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
          nil
        }
      if selectedSuggestionRow != index {
        selectedSuggestionRow = index
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
    let rowHeight: CGFloat
    let rowsOffsetY: [CGFloat]

    func rowOffsetY(for index: Int) -> CGFloat {
      rowsOffsetY[safe: index] ?? 0
    }

    static let zero = Layout(
      width: 0,
      height: 0,
      rowHeight: 0,
      rowsOffsetY: [],
    )
  }

  private let viewModel: AddressBarViewModel
  private let action: (Action) -> Void

  // @State private var initialized = false
  @State private var buffer: String = ""
  @State private var selection: Range<String.Index>?
  @State private var showEditorHighlight = false
  @State private var layout = Layout.zero
  @State private var selectedSuggestionRow: Int? // Set by moveUp / moveDown events.
  @State private var colorScheme = ColorScheme.light

  // TODO: Use a global focus state for this.
  @State private var focused: Bool?

  private var numSuggestionRows: Int {
    viewModel.suggestQueryModel?.completions.count ?? 0
  }
  
  private var suggestionRows: some View {
    Repeated(0..<numSuggestionRows, id: \.self) { index in
      Button {
        submit(suggestion(at: index))
      } label: { config in
        Group {
          Rectangle()
            .fill(suggestionRowFillColor(at: index, config: config))

          suggestionIcon(for: index)

          Text(suggestion(at: index)?.displayString ?? "")
            .font(.system(size: 13, weight: .light))
            .padding(.leading, 2 * Metrics.padding + Metrics.iconSize)
            .padding(.trailing, Metrics.padding)
            .alignment(.leading)
        }
      }
      .height(layout.rowHeight)
      .offset(y: layout.rowOffsetY(for: index))
    }
  }

  private func suggestionIcon(for index: @autoclosure @MainActor @escaping () -> Int?) -> some View {
    FaviconView(source: suggestionIconSource(at: index()))
      .width(Metrics.iconSize)
      .height(Metrics.iconSize)
      .padding(.leading, Metrics.padding)
      .alignment(.leading)
      // TODO: Consider a better way to specify this. It's a bit fragile as the goal here is to
      // match internal behavior of `FaviconView`.
      .opacity(suggestionIconOpacity(at: index()))
  }

  private func suggestionRowFillColor(at index: Int, config: ButtonConfig) -> Color {
    if index == selectedSuggestionRow {
      StandardColors.highlight.opacity(0.7)
    } else if config.isHovered {
      StandardColors.highlight.opacity(0.3)
    } else {
      .clear
    }
  }

  private func suggestionIconSource(at index: Int?) -> ImageSource {
    switch index.flatMap({ suggestion(at: $0) }) {
    case .search, .none:
      .symbol(StandardSymbols.search)
    case .navigation(let url, _):
      .pageFavicon(pageURL: url, colorScheme: colorScheme)
    }
  }

  private func suggestionIconOpacity(at index: Int?) -> CGFloat {
    switch index.flatMap({ suggestion(at: $0) }) {
    case .search, .none:
      0.7
    case .navigation:
      1
    }
  }

  private func suggestion(at index: Int) -> SuggestQueryResult? {
    viewModel.suggestQueryModel?.completions[safe: index]
  }

  private func computeLayout() -> Layout {
    let width = viewModel.placeholderSize.width

    let numSuggestions = viewModel.suggestQueryModel?.completions.count ?? 0
    let rowHeight = viewModel.placeholderSize.height
    let height = CGFloat(numSuggestions + 1) * rowHeight

    let rowsOffsetY: [CGFloat] = (0..<numSuggestions).map {
      viewModel.placeholderSize.height + CGFloat($0) * rowHeight
    }

    return .init(
      width: width,
      height: height,
      rowHeight: rowHeight,
      rowsOffsetY: rowsOffsetY,
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
      if let selectedSuggestionRow {
        submit(suggestion(at: selectedSuggestionRow))
      }
    case .cancel:
      viewModel.dismissEditor()
    case .focusNext:
      break // TODO: implement
    case .focusPrevious:
      break // TODO: implement
    case .moveUp:
      if let selectedSuggestionRow {
        self.selectedSuggestionRow = (selectedSuggestionRow - 1) % numSuggestionRows
      } else if numSuggestionRows > 0 {
        selectedSuggestionRow = 0
      } else {
        selectedSuggestionRow = nil
      }
    case .moveDown:
      if let selectedSuggestionRow {
        self.selectedSuggestionRow = (selectedSuggestionRow + 1) % numSuggestionRows
      } else if numSuggestionRows > 0 {
        selectedSuggestionRow = 0
      } else {
        selectedSuggestionRow = nil
      }
    }
  }
}