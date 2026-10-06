#if os(macOS)
import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
  static func main() throws {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    print(">>> Launched")

    let window = AppWindow()
    window.delegate = self
    window.center()
    window.makeKeyAndOrderFront(nil)
  }
}

extension AppDelegate: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    NSApplication.shared.terminate(nil)
  }
}

#elseif os(Windows)
import WinAppSupport
import WindowsFoundation
import WinUI


@main
final class App: SwiftApplication {
  override func onLaunched(_: LaunchActivatedEventArgs) {
    print(">>> onLaunched")

    MainActor.assumeIsolated {
      let window = AppWindow()
      window.initialize() {
        try! window.activate()
      }
    }
  }
}

#endif