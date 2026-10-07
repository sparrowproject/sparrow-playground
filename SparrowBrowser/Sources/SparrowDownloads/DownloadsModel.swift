import Observation
import OrderedCollections

@Observable
@MainActor
public final class DownloadsModel {
  var downloads = OrderedDictionary<DownloadID, DownloadModel>()

  init() {}
}