import SparrowProfileModel
import SparrowProfiles
import SparrowToolbelt
import SparrowWindow
import SparrowWindowModel

@MainActor
struct BrowserWindowContainer: LiveContainer {
  init(browserWindowModel: BrowserWindowModel, profileContainer: ProfileContainer) {
    self.browserWindowModel = browserWindowModel
    self.profileContainer = profileContainer
  }

  let browserWindowModel: BrowserWindowModel
  let profileContainer: ProfileContainer
}

extension BrowserWindowContainer
  : BrowserWindowModelProviding
  & BrowserWindowViewModelDependencies
  & BrowserWindowDependencies
  & ProfileContainerProviding
  & ProfileModelProviding
{}