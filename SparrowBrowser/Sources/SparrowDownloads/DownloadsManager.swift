import SparrowTabs
import SparrowToolbelt
import SparrowWeb

@MainActor
public protocol DownloadsManager {
  var model: DownloadsModel { get }

  func startDownload(_: WebDownload, forTab: TabID)
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

  func startDownload(_ webDownload: WebDownload, forTab tabID: TabID) {
    let id = DownloadID()

    let downloadModel = DownloadModel(id: id)
    downloadModel.webDownloadModel = webDownload.model

    model.downloads[id] = downloadModel
    activeDownloads[id] = webDownload

    print(">>> should call startDownloading")

    // let fileLocation = generateFileLocation(for: webDownload)

    // webDownload.startDownloading(to: fileLocation)
  }

  private let dependencies: DownloadsManagerDependencies
  private var activeDownloads = [DownloadID: WebDownload]()

  // private func generateFileLocation(for webDownload: WebDownload) -> URL {
  //   let downloadsURL = FileManager.default.url(
  //     for: .downloadsDirectory,
  //     in: .userDomainMask,
  //     appropriateFor: nil,
  //     create: false
  //   )
  //   return downloadsURL.appendPathComponent(webDownload.suggestedFilename)
  // }
}
