import SparrowDesignSystem
import SparrowUI

public struct AddressBarView: View {
  public enum Action {
    case showEditorInOverlay
  }

  public init(viewModel: AddressBarViewModel, action: @escaping @MainActor (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group { geom in
      Button(action: {
        viewModel.focusEditor(selectAll: true)
      }, label: { _ in
        Text(viewModel.content.placeholderValue)
          .font(.system(size: 13, weight: .light))
          .foregroundColor(.primaryText)
          .allowsAnimation(false)
      })
      .buttonStyle(.standard)
      .visible(viewModel.mode == .placeholder)
    }
    .readPosition(in: .host) {
      viewModel.placeholderPositionInHost = $0
    }
    .readSize {
      viewModel.placeholderSize = $0
    }
    .onChange(of: viewModel.mode) { mode in
      switch mode {
      case .editor:
        action(.showEditorInOverlay)
      case .placeholder:
        viewModel.clearSuggestions()
      }
    }
  }

  private let viewModel: AddressBarViewModel
  private let action: @MainActor (Action) -> Void
}