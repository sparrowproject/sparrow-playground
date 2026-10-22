import Foundation
import SparrowDesignSystem
import SparrowSuggest
import SparrowUI

struct SuggestionsView: View {
  enum Action {
    case submit(SuggestQueryResult?)
  }

  init(
    viewModel: SuggestionsViewModel,
    rowHeight: @autoclosure @MainActor @escaping () -> CGFloat,
    action: @escaping (Action) -> Void,
  ) {
    self.viewModel = viewModel
    self.rowHeight = rowHeight
    self.action = action
  }

  var body: some View {
    Repeated(0..<numSuggestionRows, id: \.self) { index in
      Button {
        action(.submit(viewModel.suggestionResult(at: index)))
      } label: { config in
        Group {
          Rectangle()
            .fill(suggestionRowFillColor(at: index, config: config))

          SuggestionIconView(for: viewModel.suggestionResult(at: index))
            .padding(.leading, Metrics.padding)
            .alignment(.leading)

          Text(viewModel.suggestionResult(at: index)?.value ?? "")
            .font(.system(size: 13, weight: .light))
            .padding(.leading, 2 * Metrics.padding + SuggestionIconView.Metrics.iconSize)
            .padding(.trailing, Metrics.padding)
            .alignment(.leading)
        }
      }
      .height(layout.rowHeight)
      .offset(y: layout.rowOffsetY(for: index))
    }
    .height(layout.height)
    .onChange(of: computeLayout()) { layout in
      withAnimation {
        self.layout = layout
      }
    }
  }

  private enum Metrics {
    static let padding = StandardMetrics.buttonCornerRadius
  }

  private struct Layout {
    let height: CGFloat
    let rowHeight: CGFloat
    let rowsOffsetY: [CGFloat]

    func rowOffsetY(for index: Int) -> CGFloat {
      rowsOffsetY[safe: index] ?? 0
    }

    static let zero = Layout(
      height: 0,
      rowHeight: 0,
      rowsOffsetY: [],
    )
  }

  private let viewModel: SuggestionsViewModel
  private let rowHeight: @MainActor () -> CGFloat
  private let action: (Action) -> Void

  @State private var layout = Layout.zero

  private var numSuggestionRows: Int {
    viewModel.numSuggestionResults
  }  

  private func suggestionRowFillColor(at index: Int, config: ButtonConfig) -> Color {
    if index == viewModel.selectedSuggestionRow {
      StandardColors.highlight.opacity(0.7)
    } else if config.isHovered {
      StandardColors.highlight.opacity(0.3)
    } else {
      .clear
    }
  }

  private func computeLayout() -> Layout {
    let numSuggestions = numSuggestionRows
    let rowHeight = rowHeight()
    let height = CGFloat(numSuggestions) * rowHeight

    let rowsOffsetY: [CGFloat] = (0..<numSuggestions).map {
      CGFloat($0) * rowHeight
    }

    return .init(
      height: height,
      rowHeight: rowHeight,
      rowsOffsetY: rowsOffsetY,
    )
  }
}