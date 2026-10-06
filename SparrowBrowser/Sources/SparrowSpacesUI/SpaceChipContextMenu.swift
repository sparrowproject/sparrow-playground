import SparrowDesignSystem
import SparrowUI

struct SpaceChipContextMenuView: View {
  init(
    menuData: @autoclosure @escaping () -> MenuData,
    action: @escaping (SpaceChipCommand.ID) -> Void,
  ) {
    self.menuData = menuData
    self.action = action
  }

  let menuData: () -> MenuData
  let action: (SpaceChipCommand.ID) -> Void

  var body: some View {
    Menu(data: menuData()) {
      switch $0 {
      case .command(let command):
        action((command as! SpaceChipCommand).id)
      }
    }
    .menuStyle(StandardMenuStyle())
  }
}

final class SpaceChipCommand: Command {
  enum ID: Int {
    case activate
    case save
    case delete
  }

  init(
    id: ID,
    title: String,
  ) {
    self.id = id
    self.title = title
  }

  let id: ID
  var title: String
  var isEnabled = true
}

@MainActor
enum SpaceChipCommands {
  static let activate = SpaceChipCommand(id: .activate, title: "Select")
  static let save = SpaceChipCommand(id: .save, title: "Save")
  static let delete = SpaceChipCommand(id: .delete, title: "Delete")
}