#if os(macOS)
import AppKit
import SparrowCommands
import SparrowToolbelt

@main @MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, SparrowApp {
  static func main() throws {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  func applicationWillFinishLaunching(_: Notification) {
    NSApp.mainMenu = AppMenu.build()
  }

  func applicationDidFinishLaunching(_: Notification) {
    initialize()
  }

  func applicationShouldTerminate(_ app: NSApplication) -> NSApplication.TerminateReply{
    guard let task = shutdown() else {
      print(">>> shutting down now")
      return .terminateNow
    }
    Task<Void, Never> {
      await task.value
      print(">>> resuming shutdown")
      app.reply(toApplicationShouldTerminate: true)
    }
    print(">>> deferring shutdown...")
    return .terminateLater
  }

  @objc
  func handleMenuItemAction(_ item: NSMenuItem) {
    guard let commandID = SparrowCommand.ID(rawValue: item.tag) else { return }
    appContainer.windowManager.handleCommand(commandID)
  }

  /// TODO: parameterize by profile, etc.
  let appContainer = AppContainer()
  var initializationTask: Task<Void, Never>?
}

#elseif os(Windows)
import Foundation
import WinAppSupport
import WinUI

@main @MainActor
final class App: SwiftApplication, SparrowApp, Sendable {
  override func onLaunched(_: LaunchActivatedEventArgs) {
    MainActor.assumeIsolated {
      setUpKeyboardAccelerators()
      initialize()
    }
  }

  override func onShutdown(exitCode: Int32) {
    print(">>> App.onShutdown")
    MainActor.assumeIsolated {
      guard let shutdownTask = shutdown() else { return }

      var done = false
      Task<Void, Never> {
        await shutdownTask.value
        done = true
      }

      while !done {
        if !Foundation.RunLoop.current.run(
          mode: .default,
          before: Date(timeIntervalSinceNow: 0.01)
        ) {
          print(">>> unable to spin run loop!")
          break
        }
      }
    }
  }

  /// TODO: parameterize by profile, etc.
  let appContainer = AppContainer()
  var initializationTask: Task<Void, Never>?
}

#endif

@MainActor
protocol SparrowApp: AnyObject, Sendable {
  var appContainer: AppContainer { get }
  var initializationTask: Task<Void, Never>? { get set }
}

extension SparrowApp {
  func initialize() {
    print(">>> SparrowApp.initialize()")

    initializationTask = .init {
      defer { initializationTask = nil }

      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          await self.initializeProfileSystem()
        }
        group.addTask {
          await self.initializeWindowDataStore()
        }
      }

      // await appContainer.profileSystem.initialize()
      guard !Task.isCancelled else { return }

      print(">>> SparrowApp done initializing storage system")

      if appContainer.windowManager.restoreBrowserWindows().isEmpty {
        appContainer.windowManager.createBrowserWindow(inProfile: .default)
      }
    }
  }

  func shutdown() -> Task<Void, Never>? {
    initializationTask?.cancel()

    var tasks = [Task<Void, Never>]()

    if let task = appContainer.profileSystem.shutdown() {
      tasks.append(task)
    }
    if let task = appContainer.windowDataStore.shutdown() {
      tasks.append(task)
    }
 
    return tasks.isEmpty ? nil : tasks.joined()
  }

  private func initializeProfileSystem() async {
    await appContainer.profileSystem.initialize()
  }

  private func initializeWindowDataStore() async {
    await appContainer.windowDataStore.initialize()
  }
}
