import Foundation
import SparrowDesignSystem
import SparrowUI

public struct AddressBarEditorView: View {
  public enum Action {
    case submit(String)
    case dismissed
  }

  public init(viewModel: AddressBarViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group { geom in
      RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius + 1)
        .fill(StandardColors.highlight)
        .shadow(color: StandardColors.highlightShadow, radius: 10)
        .width(geom.width + 2)
        .height(geom.height + 2)
        .offset(x: -1, y: -1)
        .opacity(showEditorHighlight ? 1 : 0)

      RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius)
        .fill(.primaryBackground)
        .visible(viewModel.mode == .editor)

      Group {
        TextEditor(
          text: $buffer,
          selection: $selection,
          action: handleTextEditorAction,
        )
        .font(.system(size: 13, weight: .light))
        .contentAlignment(.leading)
        .contentPadding(.horizontal, StandardMetrics.buttonCornerRadius)
        .visible(viewModel.mode == .editor)
        .focused(when: $focused, equals: true)
        .onAppear {
          // TODO: Can we avoid this Task somehow?
          Task {
            buffer = viewModel.content.editorValue
            selection = viewModel.content.editorSelection
            focused = true
            initialized = true
          }
        }
      }
      .height(viewModel.placeholderSize.height)

      suggestionRows
        .clipped()
    }
    .width(layout.width)
    .height(layout.height)
    .offset(x: viewModel.placeholderPositionInHost?.x ?? 0, y: viewModel.placeholderPositionInHost?.y ?? 0)
    .onChange(of: buffer, perform: { buffer in
      guard initialized, buffer != viewModel.content.editorValue else { return }
      viewModel.querySuggestions(for: buffer)
    })
    .onChange(of: viewModel.content.editorValue) {
      buffer = $0
      selection = nil
    }
    .onChange(of: viewModel.mode) { mode in
      withAnimation(mode == .editor ? .default : nil) {
        showEditorHighlight = (mode == .editor)
      }
      if initialized, mode == .placeholder {
        action(.dismissed)
      }
    }
    .onChange(of: computeLayout()) { layout in
      withAnimation {
        self.layout = layout
      }
    }
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

  @State private var initialized = false
  @State private var buffer: String = ""
  @State private var selection: Range<String.Index>?
  @State private var showEditorHighlight = false
  @State private var layout = Layout.zero
  @State private var selectedSuggestionRow: Int? // Set by moveUp / moveDown events.

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
            .fill(suggestionRowFillColor(at: index, with: config))
          Text(suggestion(at: index))
            .font(.system(size: 13, weight: .light))
            .padding(.horizontal, StandardMetrics.buttonCornerRadius)
            .alignment(.leading)
        }
      }
      .height(layout.rowHeight)
      .offset(y: layout.rowOffsetY(for: index))
    }
  }

  private func suggestionRowFillColor(at index: Int, with config: ButtonConfig) -> Color {
    if index == selectedSuggestionRow {
      StandardColors.highlight.opacity(0.7)
    } else if config.isHovered {
      StandardColors.highlight.opacity(0.5)
    } else {
      .clear
    }
  }

  private func suggestion(at index: Int) -> String {
    viewModel.suggestQueryModel?.completions[safe: index] ?? ""
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

  private func submit(_ input: String) {
    viewModel.content.editorValue = input
    viewModel.mode = .placeholder
    focused = nil
    action(.submit(input))
  }

  private func handleTextEditorAction(_ action: TextEditor.Action) {
    switch action {
    case .submit:
      if let selectedSuggestionRow {
        submit(suggestion(at: selectedSuggestionRow))
      } else {
        submit(buffer)
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