import Foundation
import SparrowDesignSystem
import SparrowDownloads
import SparrowUI

struct RecentDownloadView: View {
  enum Action {
    case cancel
    case openFile
    case openFolder
  }

  let download: DownloadModel
  let action: (Action) -> Void

  var body: some View {
    Button {
      action(.openFile)
    } label: { config in
      Group { geom in
        Group {
          Group {
            Group {
              Text(download.filename)
                .font(.system(size: Metrics.filenameFontSize))
                .foregroundColor(.primaryText)
                .elideWithGradientMask()
            }
            .height(filenameHeight(for: geom))
            
            Group {
              Text(detail)
                .font(.system(size: Metrics.detailFontSize))
                .foregroundColor(.primaryText.opacity(0.8))
                .elideWithGradientMask()
            }
            .offset(y: filenameHeight(for: geom))
            .height(detailHeight(for: geom))
          }
          .width(cardWidth(for: geom, config: config))

          cancelButton
            .width(buttonSize(for: geom))
            .height(buttonSize(for: geom))
            .alignment(.trailing)
            .visible(config.isHovered && download.isPending)

          showInFolderButton
            .width(buttonSize(for: geom))
            .height(buttonSize(for: geom))
            .alignment(.trailing)
            .visible(config.isHovered && !download.isPending)
        }
        .padding(.all, Metrics.padding)
      }
    }
    .buttonStyle(.standard)
    .onChange(
      of: download.detail,
      perform: { detail in
        // Debounce
        detailToApply = detail
        guard detailTask == nil else { return }
        self.detail = detailToApply
        detailTask = Task<Void, Never> {
          try? await Task.sleep(for: .milliseconds(200))
          self.detail = detailToApply
          detailTask = nil
        }
      }
    )
  }

  private enum Metrics {
    static let padding = StandardMetrics.buttonCornerRadius
    static let filenameFontSize: CGFloat = 11
    static let detailFontSize: CGFloat = 9
  }

  @State private var detail: String = ""
  @State private var detailToApply: String = ""
  @State private var detailTask: Task<Void, Never>?

  private var cancelButton: some View {
    Button {
      action(.cancel)
    } label: {
      Symbol(source: cancelButtonSymbol)
        .tintColor(.primaryText)
    }
    .buttonStyle(.standard)
  }

  private var showInFolderButton: some View {
    Button {
      action(.openFolder)
    } label: {
      Symbol(source: folderButtonSymbol)
        .tintColor(.primaryText)
    }
    .buttonStyle(.standard)
  }

  private var cancelButtonSymbol: SymbolSource {
    #if os(macOS)
    .init(systemName: "xmark", size: 9)
    #elseif os(Windows)
    .init(glyph: "\u{e711}", size: 9) // Cancel
    #endif
  }

  private var folderButtonSymbol: SymbolSource {
    #if os(macOS)
    .init(systemName: "folder", size: 9)
    #elseif os(Windows)
    .init(glyph: "\u{e8b7}", size: 9) // Folder
    #endif
  }

  private func buttonSize(for geom: GeometryProxy) -> CGFloat {
    geom.height - 2 * Metrics.padding
  }

  private func filenameHeight(for geom: GeometryProxy) -> CGFloat {
    let availableHeight = buttonSize(for: geom)
    return availableHeight * 0.55
  }

  private func detailHeight(for geom: GeometryProxy) -> CGFloat {
    let availableHeight = buttonSize(for: geom)
    return availableHeight * 0.45
  }

  private func cardWidth(for geom: GeometryProxy, config: ButtonConfig) -> CGFloat {
    if config.isHovered {
      geom.width - buttonSize(for: geom) - 3 * Metrics.padding
    } else {
      geom.width - 2 * Metrics.padding
    }
  }
}

extension DownloadModel {
  fileprivate var filename: String {
    fileLocation?.lastPathComponent ?? ""
  }

  fileprivate var detail: String {
    guard let webDownloadModel else { return "" }
    let displayStatus =
      switch webDownloadModel.status {
      case .starting, .downloading:
        progressDescription
      case .completed:
        "Done"
      case .cancelled:
        "Cancelled"
      case .failed:
        "Failed"
      }
    if webDownloadModel.status == .failed {
      return displayStatus
    }
    return "\(displayStatus) - \(prettyPrintBytes(webDownloadModel.bytesReceived))"
  }
  
  fileprivate var progressDescription: String {
    if
      let estimatedTimeRemaining,
      let intervalAsString = prettyPrintInterval(estimatedTimeRemaining)
    {
      return "\(intervalAsString) remaining"
    }
    return "Downloading"
  }
}

private func prettyPrintBytes(_ bytes: Int64) -> String {
  ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}

private func prettyPrintInterval(_ interval: TimeInterval) -> String? {
  Duration.seconds(interval).formatted(
    .units(
      allowed: [.hours, .minutes, .seconds],
      width: .narrow,
    )
  )
}
