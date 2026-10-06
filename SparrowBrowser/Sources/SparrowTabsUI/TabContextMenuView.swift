import SparrowCommands
import SparrowDesignSystem
import SparrowUI
import SparrowUIFoundation

struct TabContextMenuView: View {
  let tabsStyle: TabsStyle
  let isEnabled: (SparrowCommand.ID) -> Bool
  let action: (SparrowCommand.ID) -> Void

  var body: some View {
    Menu(data: menuData) {
      switch $0 {
      case .command(let command):
        action((command as! SparrowCommand).id)
      }
    }
    .menuStyle(StandardMenuStyle())
    .onAppear {
      menuData.items = [
        .command(SparrowCommands.newTabAfter(forTopTabs: tabsStyle == .topTabs)),
        .separator(),
        .command(SparrowCommands.reloadTab),
        .command(SparrowCommands.duplicateTab),
        .command(SparrowCommands.pinTab),
        .command(SparrowCommands.muteTab),
        .separator(),
        .command(SparrowCommands.toggleTabMode),
        .separator(),
        .command(SparrowCommands.closeTab),
        .command(with(SparrowCommands.closeOtherTabs) { $0.isEnabled = isEnabled($0.id) }),
        .command(with(SparrowCommands.closeTabsAfter(forTopTabs: tabsStyle == .topTabs)) { $0.isEnabled = isEnabled($0.id) }),
      ]
    }
  }

  private let menuData = MenuData()
}

