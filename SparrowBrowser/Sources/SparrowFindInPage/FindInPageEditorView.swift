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

        controls
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
    static let dividerWidth: CGFloat = 1
    static let padding: CGFloat = 6
  }

  private static var closeSymbol: SymbolSource {
    #if os(macOS)
    .init(systemName: "xmark", size: 10)
    #elseif os(Windows)
    .init(glyph: "\u{e711}", size: 10) // Cancel
    #endif
  }

  private let viewModel: FindInPageViewModel
  private let action: (Action) -> Void

  private var controls: some View {
    Group { geom in
      editor
        .width(geom.width - closeButtonWidth - 2 * Metrics.padding)

      divider
        .offset(x: geom.width - closeButtonWidth - Metrics.padding)
        .padding(.vertical, Metrics.padding / 2)

      closeButton
        .width(closeButtonWidth)
        .alignment(.trailing)
    }
    .padding(.all, Metrics.padding)
  }

  private var editor: some View {
    TextEditor(text: .init(get: { viewModel.searchString }, set: { viewModel.searchString = $0 })) {
      handleTextEditorAction($0)
    }
    .font(.system(size: 11))
    .contentPadding(.horizontal, 0)
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

  private var divider: some View {
    StandardColors.border
      .width(Metrics.dividerWidth)
      .offset(x: Metrics.dividerWidth / 2)
  }

  private var closeButton: some View {
    Button {
      action(.dismiss)
    } label: {
      Symbol(source: Self.closeSymbol)
    }
    .buttonStyle(.standard)
  }

  private var closeButtonWidth: CGFloat {
    Metrics.height - 2 * Metrics.padding
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
    case .focusNext, .focusPrevious, .moveUp, .moveDown, .textChanged:
      print(">>> unhandled editor action: \(action)")
    }
  }
}