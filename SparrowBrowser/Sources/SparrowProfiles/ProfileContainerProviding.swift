import SparrowNetwork
import SparrowProfileModel
import SparrowSpaces
import SparrowSuggest
import SparrowTabs
import SparrowToolbelt
import SparrowWeb
import SparrowWindowModel

public protocol ProfileContainerProviding {
  @MainActor
  var profileContainer: ProfileContainer { get }
}

extension LiveContainer where Self: ProfileContainerProviding & NetworkServiceProviding {
  @MainActor
  public var networkService: NetworkService {
    profileContainer.networkService
  }
}

extension LiveContainer where Self: ProfileContainerProviding & ProfileModelProviding {
  @MainActor
  public var profileModel: ProfileModel {
    profileContainer.profileModel
  }
}

extension LiveContainer where Self: ProfileContainerProviding & SpaceGridModelProviding {
  @MainActor
  public var spaceGridModel: SpaceGridModel {
    profileContainer.spaceGridModel
  }
}

extension LiveContainer where Self: ProfileContainerProviding & SuggestServiceProviding {
  @MainActor
  public var suggestService: SuggestService {
    profileContainer.suggestService
  }
}

extension LiveContainer where Self: ProfileContainerProviding & TabSystemProviding {
  @MainActor
  public var tabSystem: TabSystem {
    profileContainer.tabSystem
  }
}

extension LiveContainer where Self: ProfileContainerProviding & WebHistoryProviding {
  @MainActor
  public var webHistory: WebHistory {
    profileContainer.webHistory
  }
}

extension LiveContainer where Self: ProfileContainerProviding & WindowSystemModelProviding {
  @MainActor
  public var windowSystemModel: WindowSystemModel {
    profileContainer.windowSystemModel
  }
}