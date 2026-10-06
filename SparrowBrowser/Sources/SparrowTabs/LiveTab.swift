import SparrowWeb

@MainActor
public protocol LiveTab {
  var tabID: TabID { get }
  var webContent: WebContent { get }

  func load(_: TabNavigation)
}

public typealias LiveTabDependencies
  = WebContentFactoryProviding

@MainActor
final class DefaultLiveTab {
  init(
    dependencies: LiveTabDependencies,
    tabModel: TabModel,
    webContent: WebContent? = nil,
  ) {
    self.dependencies = dependencies
    self.tabModel = tabModel

    let webContent = webContent ?? dependencies.webContentFactory.createWebContent(initializationParams: {
      if let data = tabModel.interactionState {
        .interactionState(data)
      } else if let url = tabModel.url {
        .url(url)
      } else {
        nil
      }
    }())
    self.webContent = webContent

    tabModel.webContentModel = webContent.model
  }

  let dependencies: LiveTabDependencies
  let tabModel: TabModel
  let webContent: WebContent
}

extension DefaultLiveTab: LiveTab {
  var tabID: TabID { tabModel.id }

  func load(_ navigation: TabNavigation) {
    webContent.load(url: navigation.url)
  }
}
