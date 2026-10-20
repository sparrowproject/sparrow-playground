import Foundation
import Observation
import SparrowAddressBar
import SparrowFindInPage
import SparrowTabs
import SparrowToolbelt
import SparrowUIFoundation
import SparrowSpacesUI
import SparrowWeb

public typealias BrowserWindowOverlayViewModelDependencies
  = WebHistoryProviding

@Observable
@MainActor
final class BrowserWindowOverlayViewModel {
  init(dependencies: BrowserWindowOverlayViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel
  }

  let dependencies: BrowserWindowOverlayViewModelDependencies

  var findInPageViewModel: FindInPageViewModel? {
    didSet {
      if findInPageViewModel != nil {
        addressBarViewModel = nil
      }
    }
  }

  var addressBarViewModel: AddressBarViewModel? {
    didSet {
      if addressBarViewModel != nil {
        findInPageViewModel = nil
      }
    }
  }

  var needsHitTesting: Bool {
    (findInPageViewModel != nil) || (addressBarViewModel != nil)
  }

  var contentToolbarHeight: CGFloat = 0
  var contentViewInsets = EdgeInsets.zero

  var showModalCover: Bool {
    addressBarViewModel != nil
  }

  private let groupModel: Handle<TabGroupModel>
}

extension BrowserWindowOverlayViewModel: @MainActor Identifiable {
  var id: ObjectIdentifier { .init(self) }
}