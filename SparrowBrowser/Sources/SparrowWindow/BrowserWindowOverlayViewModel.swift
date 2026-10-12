import Foundation
import Observation
import SparrowAddressBar
import SparrowFindInPage
import SparrowTabs
import SparrowToolbelt
import SparrowUIFoundation
import SparrowSpacesUI

public typealias BrowserWindowOverlayViewModelDependencies
  = Any

@Observable
@MainActor
final class BrowserWindowOverlayViewModel {
  init(dependencies: BrowserWindowOverlayViewModelDependencies, groupModel: Handle<TabGroupModel>) {
    self.dependencies = dependencies
    self.groupModel = groupModel
  }

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

  var contentToolbarHeight: CGFloat = 0
  var contentViewInsets = EdgeInsets.zero

  var showModalCover: Bool {
    addressBarViewModel != nil
  }

  var needsHitTesting: Bool {
    addressBarViewModel != nil
  }

  private let dependencies: BrowserWindowOverlayViewModelDependencies
  private let groupModel: Handle<TabGroupModel>
}

extension BrowserWindowOverlayViewModel: @MainActor Identifiable {
  var id: ObjectIdentifier { .init(self) }
}