import SparrowWeb

typealias LiveTabsManagerDependencies
  = LiveTabDependencies

@MainActor
final class LiveTabsManager {
  enum Action {
    case createNewTabWithContent(WebContent, openerID: TabID)
  }

  init(dependencies: LiveTabsManagerDependencies, model: TabSystemModel) {
    self.dependencies = dependencies
    self.model = model
  }

  var action: ((Action) -> Void)?

  func get(byID tabID: TabID) -> LiveTab? {
    model.liveTabs[tabID]
  }

  func create(forModel tabModel: TabModel, withWebContent webContent: WebContent? = nil) -> LiveTab? {
    guard !model.liveTabs.keys.contains(tabModel.id) else {
      assertionFailure("LiveTab already exists!")
      return nil
    }

    // let initialURL = tabModel.url

    let liveTab = DefaultLiveTab(dependencies: dependencies, tabModel: tabModel, webContent: webContent)
    liveTab.webContent.action = { [weak self] in
      self?.handleWebContentAction($0, tabID: tabModel.id)
    }

    model.liveTabs[tabModel.id] = liveTab

    // if let initialURL {
    //   liveTab.load(.init(url: initialURL))
    // }
    return liveTab
  }

  func getOrCreate(forModel tabModel: TabModel) -> LiveTab? {
    guard tabModel.id != .invalid else { return nil }
    if let liveTab = model.liveTabs[tabModel.id] {
      return liveTab
    }
    return create(forModel: tabModel)
  }

  func remove(byID tabID: TabID) {
    model.liveTabs.removeValue(forKey: tabID)
  }

  private let dependencies: LiveTabsManagerDependencies
  private let model: TabSystemModel

  private func handleWebContentAction(_ action: WebContentAction, tabID: TabID) {
    switch action {
    case .createdNew(let webContent):
      self.action?(.createNewTabWithContent(webContent, openerID: tabID))
    }
  }
}