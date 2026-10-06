import SparrowUI
import SparrowWeb

struct ContentBody: View {
  let viewModel: ContentBodyViewModel

  var body: some View {
    WebContentView(viewModel: viewModel.webContentViewModel)
      .onChange(of: viewModel.liveTabs) {
        viewModel.handleLiveTabsChanged($0)
      }
      .onChange(of: viewModel.groupModel.selectedTabModel.id) {
        viewModel.handleSelectedTabChanged($0)
      }
  }
}