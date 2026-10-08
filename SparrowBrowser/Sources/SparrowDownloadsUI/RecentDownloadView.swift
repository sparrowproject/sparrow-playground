import Foundation
import SparrowDesignSystem
import SparrowDownloads
import SparrowUI

struct RecentDownloadView: View {
  enum Action {
    case openFile
    case openFolder
  }

  let download: DownloadModel
  let action: (Action) -> Void

  var body: some View {
    Button {
      action(.openFile)
    } label: { config in
      Group {
        Group {
          Text(download.filename)
            .font(.system(size: 12))
            .elideWithGradientMask()

          showInFolderButton
            .alignment(.trailing)
            .visible(config.isHovered)
        }
        .padding(.horizontal, StandardMetrics.buttonCornerRadius)
      }
    }
    .buttonStyle(.standard)
  }

  private enum Metrics {
    static let folderButtonSize = 4 * StandardMetrics.buttonCornerRadius
  }

  private var showInFolderButton: some View {
    Button {
      action(.openFolder)
    } label: {
      Symbol(source: folderButtonSymbol)
        .tintColor(.primaryText)
    }
    .buttonStyle(.standard)
    .width(Metrics.folderButtonSize)
    .height(Metrics.folderButtonSize)
  }

  private var folderButtonSymbol: SymbolSource {
    #if os(macOS)
    .init(systemName: "folder", size: 9)
    #elseif os(Windows)
    // XXX  .init(glyph: "\u{e711}", size: 9) // Cancel
    #endif
  }
}

extension DownloadModel {
  fileprivate var filename: String {
    fileLocation?.lastPathComponent ?? ""
  }

  // fileprivate var detail: String {
    
  // }
}

private func prettyPrintBytes(_ bytes: Int) -> String {
  ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}
