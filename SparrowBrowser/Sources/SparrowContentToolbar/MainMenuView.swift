import SparrowCommands
import SparrowDesignSystem
import SparrowUI
import SparrowUIFoundation

struct MainMenuView: View {
  let action: (SparrowCommand.ID) -> Void

  var body: some View {
    Menu(data: menuData) {
      switch $0 {
      case .command(let command):
        action((command as! SparrowCommand).id)
      }
    }
    .menuStyle(StandardMenuStyle())
  }

  private let menuData = MenuData(items: [
    .command(SparrowCommands.newTab),
    .command(SparrowCommands.newWindow),
    .command(SparrowCommands.newIncognitoWindow),

    // .separator(),
    // .command(SparrowCommand(title: "History")),
    // .command(SparrowCommand(title: "Downloads", keybinding: .downloads)),
    // .command(SparrowCommand(title: "Bookmarks")),
    // .command(SparrowCommand(title: "Extensions")),
    // .command(SparrowCommand(title: "Delete browsing data...")),
    // .command(SparrowCommand(title: "Zoom")),
    // .separator(),
    // .command(SparrowCommand(title: "Print...", keybinding: .print)),
    // .command(SparrowCommand(title: "Translate...")),
    // .submenu(.init(title: "Find and edit", items: [
    //   .command(SparrowCommand(title: "Find...", keybinding: .find)),
    //   .separator(),
    //   .command(SparrowCommand(title: "Cut", keybinding: .cut)),
    //   .command(SparrowCommand(title: "Copy", keybinding: .copy)),
    //   .command(SparrowCommand(title: "Paste", keybinding: .paste)),
    // ])),
    // .command(SparrowCommand(title: "Save and share")),
    // .command(SparrowCommand(title: "More tools")),
    // .separator(),
    // .command(SparrowCommand(title: "Help")),
    // .command(SparrowCommand(title: "Settings", keybinding: .settings)),
    // .command(SparrowCommand(title: "Exit")),
  ])
}
