import SparrowContentToolbar
import SparrowUI

public struct ContentView: View {
  public enum Action {
    case toolbar(ContentToolbarView.Action)
  }

  public init(viewModel: ContentViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Group {
      contentToolbar
      contentBody
    }
  }

  public var contentToolbar: some View {
    ContentToolbarView(viewModel: viewModel.contentToolbarViewModel, action: { action(.toolbar($0)) })
      .height(viewModel.toolbarHeight)
      .alignment(.top)
  }

  public var contentBody: some View {
    ContentBody(viewModel: viewModel.contentBodyViewModel)
      .padding(.top, viewModel.toolbarHeight)
      .onPointerDown {
        // Consume pointer down here to prevent window movement.
        $0.handled = true
      }
  }

  private let viewModel: ContentViewModel
  private let action: (Action) -> Void
}