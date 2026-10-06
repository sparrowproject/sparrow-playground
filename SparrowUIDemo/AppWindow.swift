import Foundation
import SparrowUI

#if os(macOS)
import AppKit

final class AppWindow: NSWindow {
  init() {
    let initialSize = CGSize(width: 1000, height: 600)
    super.init(
      contentRect: .init(origin: .zero, size: initialSize),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    title = "SparrowUI Demo App"
    contentView = NSHostingView(content: AppView(viewModel: AppViewModel()))
  }
}

#elseif os(Windows)
import CWinAppSDK
import WinUI

@MainActor
final class AppWindow: Window {
  func initialize(completion: @MainActor @escaping () -> Void) {
    title = "SparrowUI Demo App"

    content = hostingView

    hostingView.loaded.addHandler { [weak self] _, _ in
      self?.onLoaded()
      completion()
    }
  }

  private lazy var hostingView = WinUIHostingView(content: AppView(viewModel: AppViewModel()))

  private func onLoaded() {
    let scale = hostingView.xamlRoot!.rasterizationScale
    try! appWindow.resize(.init(width: Int32(1000 * scale), height: Int32(600 * scale)))
  }
}

#endif