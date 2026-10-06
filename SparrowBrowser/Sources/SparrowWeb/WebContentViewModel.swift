import Foundation
import Observation
import SparrowUIFoundation

public typealias WebContentViewModelDependencies
  = WebHistoryProviding

@MainActor
@Observable
public final class WebContentViewModel {
  public init(dependencies: WebContentViewModelDependencies) {
    self.dependencies = dependencies
  }

  public var allWebContent = [WebContent]()
  public var selectedWebContent: WebContent?
  public var inputDisabled = false

  @ObservationIgnored var updateFaviconTask: Task<Void, Never>?

  let dependencies: WebContentViewModelDependencies

  func handleURLChanged(_ url: URL?, colorScheme: ColorScheme) {
    let model = selectedWebContent?.model
    guard let url, let model else { return }
    let lastValue = model.faviconURL
    updateFaviconTask?.cancel()
    updateFaviconTask = Task<Void, Never> {
      let faviconURL = await dependencies.webHistory.queryFaviconURL(
        forPageURL: url,
        withColorScheme: colorScheme,
      )
      guard !Task.isCancelled else { return }
      // If the value was already changed, perhaps due to parsing the HTML, then ignore the
      // historical value.
      if model.faviconURL == lastValue {
        model.faviconURL = faviconURL
      }
      updateFaviconTask = nil
    }
  }
}