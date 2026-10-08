import Observation
import OrderedCollections
import SparrowDownloads
import Tagged

public typealias RecentDownloadsViewModelDependencies
  = DownloadsManagerProviding

@Observable
@MainActor
public final class RecentDownloadsViewModel {
  public init(dependencies: RecentDownloadsViewModelDependencies) {
    self.dependencies = dependencies

    Task<Void, Never> {
      for await downloads in Observations({
        OrderedDictionary<DownloadID, DownloadModel>(
          uniqueKeysWithValues: dependencies.downloadsManager.model.recentDownloads().map { ($0.id, $0) }
        )
      }) {
        self.downloads = downloads
      }
    }
  }

  public var downloads = OrderedDictionary<DownloadID, DownloadModel>()

  public var isEmpty: Bool {
    count == 0
  }

  public var count: Int {
    downloads.values.count
  }

  let dependencies: RecentDownloadsViewModelDependencies
}