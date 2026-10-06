import Foundation
import Observation
import SparrowUIFoundation

@MainActor
@Observable
public final class MenuData {
  /// An item is identified by its address in memory.
  @MainActor
  @Observable
  public final class Item: NSObject {
    public enum Kind {
      case command(Command)
      case separator
      case submenu(MenuData)
    }

    init(kind: Kind) {
      self.kind = kind
    }

    public let kind: Kind

    public var title: String? {
      switch kind {
      case .command(let command):
        command.title
      case .separator:
        nil
      case .submenu(let data):
        data.title
      }
    }

    public var icon: ImageSource? {
      switch kind {
      case .command(let command):
        command.icon
      case .separator:
        nil
      case .submenu(let data):
        data.icon
      }
    }

    public static func command(_ command: Command) -> Self {
      .init(kind: .command(command))
    }

    public static func separator() -> Self {
      .init(kind: .separator)
    }

    public static func submenu(_ data: MenuData) -> Self {
      .init(kind: .submenu(data))
    }
  }

  public init(
    title: String? = nil,
    icon: ImageSource? = nil,
    items: [Item] = [],
  ) {
    self.title = title
    self.icon = icon
    self.items = items
  }

  public var title: String?
  public var icon: ImageSource?
  public var items = [Item]()
}

extension MenuData.Item: Identifiable {}