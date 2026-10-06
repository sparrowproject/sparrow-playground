import SparrowAddressBar
import SparrowDesignSystem
import SparrowSpacesUI
import SparrowUI

#if os(macOS)
import AppKit
#elseif os(Windows)
import WinUI
#endif

/// This view is positioned on top of the `BrowserWindowView` enabling content to
/// be layered on top of native UI elements such as the web view.
struct BrowserWindowOverlayView: View {
  enum Action {
    case addressBarEditor(AddressBarEditorView.Action)
    case spaceSelector(SpaceSelectorView.Action)
  }

  let viewModel: BrowserWindowOverlayViewModel
  let action: (Action) -> Void

  var body: some View {
    Group {
      Group { geom in
        modalCover
        // TODO: insert other UI anchored to the content area
      }
      .padding(webContentInsets)

      IfLet(viewModel.addressBarViewModel) {
        addressBarEditorView(for: $0)
      }
    }
    .onPointerDown {
      if let addressBarViewModel = viewModel.addressBarViewModel {
        addressBarViewModel.dismissEditor()
      }
    }
  }

  @State private var modalCoverOpacity: Double = 0

  private var modalCover: some View {
    Color(light: .black.opacity(0.1), dark: .black.opacity(0.2))
      .opacity(modalCoverOpacity)
      .allowsHitTesting(viewModel.showModalCover)
      .cursor(.arrow)
      .onAppear {
        if viewModel.showModalCover {
          withAnimation {
            modalCoverOpacity = 1
          }
        } else {
          modalCoverOpacity = 0
        }
      }
  }

  private func addressBarEditorView(for addressBarViewModel: AddressBarViewModel) -> some View {
    AddressBarEditorView(viewModel: addressBarViewModel) {
      action(.addressBarEditor($0))
    }
  }

  private var webContentInsets: EdgeInsets {
    .init(
      leading: viewModel.contentViewInsets.leading,
      trailing: viewModel.contentViewInsets.trailing,
      top: viewModel.contentViewInsets.top + viewModel.contentToolbarHeight,
      bottom: viewModel.contentViewInsets.bottom,
    )
  }
}