import Observation
import SparrowTabs
import SparrowToolbelt
import SparrowWeb

@MainActor
public protocol DownloadsManager {
  var model: DownloadsModel { get }

  @discardableResult
  func startDownload(_: WebDownload, forTab: TabID) -> DownloadID

  func cancelDownload(withID: DownloadID)
}

public protocol DownloadsManagerProviding {
  @MainActor
  var downloadsManager: DownloadsManager { get }
}

public typealias DownloadsManagerDependencies
  = Any

extension Factory where Interface == DownloadsManager {
  public static func makeDefaultInstance(dependencies: DownloadsManagerDependencies) -> DownloadsManager {
    DefaultDownloadsManager(dependencies: dependencies)
  }
}

final class DefaultDownloadsManager: DownloadsManager {
  init(dependencies: DownloadsManagerDependencies) {
    self.dependencies = dependencies
  }

  let model = DownloadsModel()

  func startDownload(_ webDownload: WebDownload, forTab tabID: TabID) -> DownloadID {
    let id = DownloadID()

    let downloadModel = DownloadModel(id: id)
    downloadModel.webDownloadModel = webDownload.model

    model.downloads[id] = downloadModel
    activeDownloads[id] = webDownload

    // Monitor the download to determine when it is no longer active.
    Task<Void, Never> {
      for await isPending in Observations({ downloadModel.isPending }) {
        if !isPending {
          activeDownloads.removeValue(forKey: id)          
        }
      }
    }

    return id
  }

  func cancelDownload(withID id: DownloadID) {
    activeDownloads.removeValue(forKey: id)?.cancel()
  }

  private let dependencies: DownloadsManagerDependencies
  private var activeDownloads = [DownloadID: WebDownload]()
}
