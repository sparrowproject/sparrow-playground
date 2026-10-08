import Foundation
import Observation
import OrderedCollections

@Observable
@MainActor
public final class DownloadsModel {
  var downloads = OrderedDictionary<DownloadID, DownloadModel>()

  init() {}
}

extension DownloadsModel {
  func recentDownloads(within duration: Duration) -> some Sequence<DownloadModel> {
    let dateInThePast = Date.now - duration.timeInterval
    return downloads.values.filter { $0.creationTime >= dateInThePast }
  }
}