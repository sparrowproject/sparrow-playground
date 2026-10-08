import Foundation
import SparrowDesignSystem
import SparrowDownloads
import SparrowUI

public struct RecentDownloadsView: View {
  public enum Action {
    case openFile(for: DownloadID)
    case openFolder(for: DownloadID)
  }

  public init(viewModel: RecentDownloadsViewModel, action: @escaping (Action) -> Void) {
    self.viewModel = viewModel
    self.action = action
  }

  public var body: some View {
    Repeated(viewModel.downloads.values) { download in
      RecentDownloadView(download: download, action: {
        handleDownloadAction($0, for: download)
      })
      .offset(y: offsetY(for: download))
      .padding(.horizontal, Metrics.itemPadding)
      .height(Metrics.itemHeight)
    }
    .width(Metrics.width)
    .height(height)
  }

  private enum Metrics {
    static let width: CGFloat = 250
    static let itemHeight: CGFloat = 40
    static let itemPadding = StandardMetrics.buttonCornerRadius
  }

  private let viewModel: RecentDownloadsViewModel
  private let action: (Action) -> Void

  private var height: CGFloat {
    CGFloat(viewModel.count) * (Metrics.itemHeight + Metrics.itemPadding) + Metrics.itemPadding
  }

  private func offsetY(for download: DownloadModel) -> CGFloat {
    guard let index = viewModel.downloads.keys.firstIndex(of: download.id) else { return 0 }
    return CGFloat(index) * (Metrics.itemHeight + Metrics.itemPadding) + Metrics.itemPadding
  }

  private func handleDownloadAction(_ action: RecentDownloadView.Action, for download: DownloadModel) {
    switch action {
    case .openFile:
      self.action(.openFile(for: download.id))
    case .openFolder:
      self.action(.openFolder(for: download.id))
    }
  }
}
