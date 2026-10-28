import Foundation
import SparrowDesignSystem
import SparrowUI

public struct FindInPageEditorView: View {
  public enum Action {
    case dismiss
  }

  public init(viewModel: FindInPageViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      Group {
        RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius)
          .fill(StandardColors.border.opacity(0.5))

        RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius - 1)
          .fill(.primaryBackground)
          .padding(.all, 1)

        editor
      }
      .shadow(color: StandardColors.shadow, radius: StandardMetrics.shadowRadius)
    }
    .width(Metrics.width)
    .height(Metrics.height)
    .padding(.all, 2)
    .alignment(.topTrailing)
  }

  @MainActor
  private enum Metrics {
    static let width: CGFloat = 200
    static let height: CGFloat = 36
  }

  private let viewModel: FindInPageViewModel
  private let action: (Action) -> Void

  private var editor: some View {
    TextEditor(text: .init(get: { viewModel.searchString }, set: { viewModel.searchString = $0 })) {
      handleTextEditorAction($0)
    }
    .font(.system(size: 11))
    .foregroundColor(.primaryText)
    .alignment(.leading)
    .focused(when: focusedBinding, equals: true)
    .onAppear {
      // TODO: Can we avoid this Task somehow?
      Task {
        viewModel.isEditorFocused = true
      }
    }
  }

  private var focusedBinding: Binding<Bool?> {
    .init(
      get: { viewModel.isEditorFocused },
      set: { viewModel.isEditorFocused = $0 }
    )
  }

  private func handleTextEditorAction(_ action: TextEditor.Action) {
    switch action {
    case .submit:
      viewModel.findNext()
    case .cancel:
      self.action(.dismiss)
    case .focusNext, .focusPrevious, .moveUp, .moveDown, .changed:
      print(">>> unhandled editor action: \(action)")
    }
  }
}