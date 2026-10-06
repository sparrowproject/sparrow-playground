import SparrowUI

public struct WebContentView: View {
  public init(viewModel: WebContentViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    Group {
      Color.primaryBackground
      WebContentRepresentable(viewModel: viewModel)
    }
    .readColorScheme(to: $colorScheme)
    .onChange(of: viewModel.selectedWebContent?.model.url) {
      viewModel.handleURLChanged($0, colorScheme: colorScheme)
    }
  }

  private let viewModel: WebContentViewModel
  @State private var colorScheme = ColorScheme.light
}