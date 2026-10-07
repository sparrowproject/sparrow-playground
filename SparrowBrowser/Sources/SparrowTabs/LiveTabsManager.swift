import SparrowWeb

typealias LiveTabsManagerDependencies
  = LiveTabDependencies

@MainActor
final class LiveTabsManager {
  enum Action {
    case createNewTabWithContent(WebContent, requestingTab: TabID)
    case startDownload(WebDownload, requestingTab: TabID)
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

    let liveTab = DefaultLiveTab(dependencies: dependencies, tabModel: tabModel, webContent: webContent)
    liveTab.webContent.action = { [weak self] in
      self?.handleWebContentAction($0, tabID: tabModel.id)
    }

    model.liveTabs[tabModel.id] = liveTab
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
      self.action?(.createNewTabWithContent(webContent, requestingTab: tabID))
    case .downloadStarting(let webDownload):
      self.action?(.startDownload(webDownload, requestingTab: tabID))
    }
  }
}