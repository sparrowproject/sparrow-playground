import Foundation
import Observation
import OrderedCollections
import Tagged

@Observable
@MainActor
public final class DownloadsModel {
  public var downloads = OrderedDictionary<DownloadID, DownloadModel>()

  public init() {}
}

extension DownloadsModel {
  public func recentDownloads(
    within duration: Duration = .seconds(60 * 60),
  ) -> some RandomAccessCollection<DownloadModel> {
    let dateInThePast = Date.now - duration.timeInterval
    return downloads.values.filter({ $0.creationTime >= dateInThePast })
  }
}