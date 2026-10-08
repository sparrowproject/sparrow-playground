import Foundation
import SparrowDownloads
import SparrowStorageBase
import SparrowToolbelt

public typealias DownloadInfoStoreDependencies
  = DownloadsManagerProviding
  & StoragePathsProviding

@MainActor
final class DownloadInfoStore: StorageComponent {
  init(dependencies: DownloadInfoStoreDependencies) {
    self.dependencies = dependencies
  }

  func initialize() async {
    let downloads = await readDownloads().map {
      $0.makeDownloadModel()
    }

    let downloadsModel = dependencies.downloadsManager.model
    for download in downloads {
      downloadsModel.downloads[download.id] = download
    }

    observationTask = .init(operation: observeDownloads)
  }

  func shutdown() -> ShutdownTask? {
    observationTask?.cancel()
    observationTask = nil

    objectWriter.write(dependencies.downloadsManager.model.downloadInfoArray)
    objectWriter.flush()

    return nil
  }

  private let dependencies: DownloadInfoStoreDependencies
  private var observationTask: Task<Void, Never>?

  private lazy var storagePath = dependencies.storagePaths.userDataDirectory.appendingPathComponent("downloads.json")
  private lazy var objectWriter = ObjectWriter<[DownloadInfo]>(fileURL: storagePath)

  private func readDownloads() async -> [DownloadInfo] {
    await withCheckedContinuation { continuation in
      DispatchQueue(label: "downloads-reader").async { [storagePath] in
        var result = [DownloadInfo]()
        let decoder = JSONDecoder()
        do {
          let data = try Data(contentsOf: storagePath)
          result = try decoder.decode([DownloadInfo].self, from: data)
        } catch {
          print(">>> error reading downloads list: \(error)")
        }
        continuation.resume(returning: result)
      }
    }
  }

  private func observeDownloads() async {
    let downloadsModel = dependencies.downloadsManager.model
    for await downloads in Observations({ [downloadsModel] in
      downloadsModel.downloadInfoArray
    }) {
      objectWriter.write(downloads)
    }
  }
}

extension DownloadsModel {
  fileprivate var downloadInfoArray: [DownloadInfo] {
    downloads.values.map { DownloadInfo.from($0) }
  }
}