#if os(macOS)
import AppKit
import SparrowCommands
import SparrowUIFoundation

@MainActor
enum AppMenu {
  static func build() -> NSMenu {
    let mainMenu = NSMenu()

    mainMenu.addItem(buildAppMenu())
    mainMenu.addItem(buildFileMenu())
    mainMenu.addItem(buildEditMenu())
    mainMenu.addItem(buildHistoryMenu())
    mainMenu.addItem(buildWindowMenu())

    return mainMenu
  }

  private static func buildAppMenu() -> NSMenuItem {
    let appMenuItem = NSMenuItem()

    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu

    let appName =
      Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? ProcessInfo.processInfo.processName

    appMenu.addItem(
      withTitle: "About \(appName)",
      action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
      keyEquivalent: ""
    )

    appMenu.addItem(.separator())

    appMenu.addCommand(SparrowCommands.quit)

    return appMenuItem
  }

  private static func buildFileMenu() -> NSMenuItem {
    let fileMenuItem = NSMenuItem(
      title: "File",
      action: nil,
      keyEquivalent: "",
    )

    let fileMenu = NSMenu()
    fileMenuItem.submenu = fileMenu

    fileMenu.addCommand(SparrowCommands.newTab)
    fileMenu.addCommand(SparrowCommands.newWindow)
    fileMenu.addCommand(SparrowCommands.newIncognitoWindow)
    fileMenu.addCommand(SparrowCommands.openLocation)

    fileMenu.addItem(.separator())

    fileMenu.addCommand(SparrowCommands.closeWindow)
    fileMenu.addCommand(SparrowCommands.closeTab)

    return fileMenuItem
  }

  private static func buildEditMenu() -> NSMenuItem {
    let editMenuItem = NSMenuItem(
      title: "Edit",
      action: nil,
      keyEquivalent: "",
    )

    let editMenu = NSMenu()
    editMenuItem.submenu = editMenu

    with(NSMenuItem(
      title: "Cut",
      action: #selector(EditingSupport.cut),
      keyEquivalent: "x",
    )) {
      $0.keyEquivalentModifierMask = [.command]
      editMenu.addItem($0)
    }

    with(NSMenuItem(
      title: "Copy",
      action: #selector(EditingSupport.copy),
      keyEquivalent: "c",
    )) {
      $0.keyEquivalentModifierMask = [.command]
      editMenu.addItem($0)
    }

    with(NSMenuItem(
      title: "Paste",
      action: #selector(EditingSupport.paste),
      keyEquivalent: "v",
    )) {
      $0.keyEquivalentModifierMask = [.command]
      editMenu.addItem($0)
    }

    with(NSMenuItem(
      title: "Select All",
      action: #selector(EditingSupport.selectAll),
      keyEquivalent: "a",
    )) {
      $0.keyEquivalentModifierMask = [.command]
      editMenu.addItem($0)
    }

    return editMenuItem
  }

  private static func buildHistoryMenu() -> NSMenuItem {
    let historyMenuItem = NSMenuItem(
      title: "History",
      action: nil,
      keyEquivalent: "",
    )

    let historyMenu = NSMenu()
    historyMenuItem.submenu = historyMenu

    historyMenu.addCommand(SparrowCommands.goBack)
    historyMenu.addCommand(SparrowCommands.goForward)

    // Add alternative keybindings for goBack & goForward:

    historyMenu.addHiddenCommand(SparrowCommands.goBackAlt)
    historyMenu.addHiddenCommand(SparrowCommands.goForwardAlt)

    return historyMenuItem
  }

  private static func buildWindowMenu() -> NSMenuItem {
    let windowMenuItem = NSMenuItem(
      title: "Window",
      action: nil,
      keyEquivalent: "",
    )

    let windowMenu = NSMenu()
    windowMenuItem.submenu = windowMenu

    windowMenu.addItem(.separator())
    windowMenu.addCommand(SparrowCommands.selectNextTab)
    windowMenu.addCommand(SparrowCommands.selectPreviousTab)
    for index in 0...9 {
      windowMenu.addHiddenCommand(SparrowCommands.selectTabAt(index: index))
    }
    windowMenu.addCommand(SparrowCommands.duplicateTab)

    NSApp.windowsMenu = windowMenu

    return windowMenuItem
  }
}

extension NSMenu {
  @MainActor
  fileprivate func addCommand(_ command: SparrowCommand, configure: (inout NSMenuItem) -> Void = { _ in }) {
    var item = NSMenuItem(
      title: command.title,
      action: #selector(AppDelegate.handleMenuItemAction(_:)),
      keyEquivalent: command.keybinding?.keyEquivalent ?? "",
    )
    item.keyEquivalentModifierMask = command.keybinding?.modifiers ?? []
    item.target = NSApp.delegate
    item.tag = command.id.rawValue
    configure(&item)
    addItem(item)    
  }

  @MainActor
  fileprivate func addHiddenCommand(_ command: SparrowCommand) {
    addCommand(command) {
      $0.isHidden = true
      $0.allowsKeyEquivalentWhenHidden = true
    }
  }
}

// AppKit doesn't seem to define such a protocol, else we could just use it instead.
@objc
private protocol EditingSupport {
  func cut(_: Any?)
  func copy(_: Any?)
  func paste(_: Any?)
  func selectAll(_: Any?)
}

#endif