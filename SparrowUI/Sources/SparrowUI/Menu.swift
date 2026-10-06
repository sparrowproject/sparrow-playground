import Foundation
import Observation

public struct Menu: View {
  public enum Action {
    case command(Command)
  }

  public init(data: MenuData, action: @escaping (Action) -> Void) {
    self.data = data
    self.action = action
    style = DefaultStyleAdapter(style: _BlankMenuStyle())
  }

  private init(data: MenuData, action: @escaping (Action) -> Void, style: any StyleAdapter) {
    self.data = data
    self.action = action
    self.style = style
  }

  public var body: some View {
    Repeated(data.items) { item in
      itemView(for: item)
        .width(itemRect(for: item).width)
        .height(itemRect(for: item).height)
        .offset(x: itemRect(for: item).minX, y: itemRect(for: item).minY)
        .onPointerEntered {
          itemConfig(for: item).isHovered = true
        }
        .onPointerExited {
          itemConfig(for: item).isHovered = false
        }
        .onPointerUp {
          tryActivate(item: item)
        }
    }
    .width(state.layout.size.width)
    .height(state.layout.size.height)
    .onChange(of: data.items) { items in
      var newConfig = [MenuData.Item.ID: MenuItemConfig]()
      for item in items {
        newConfig[item.id] = state.configs[item.id, default: .init()]
      }
      state.configs = newConfig
    }
    .onChange(of: style.computeLayout(for: data)) {
      state.layout = $0
    }
    .onPointerMoved {
      // Unlock immediately if there is pointer motion. Allows for a quick press, drag
      // and release to activate a menu item.
      state.activationLocked = false
    }
    .onAppear {
      Task<Void, Never> {
        // In case the menu appears under the pointer, prevent a click used to activate
        // the menu from triggering an item.
        try? await Task.sleep(for: .seconds(0.2))
        state.activationLocked = false
      }
    }
  }

  @Observable
  final class State {
    var layout = MenuLayout()
    var configs = [MenuData.Item.ID: MenuItemConfig]()
    var hasActivation = false
    var activationLocked = true
  }

  private let data: MenuData
  private let action: (Action) -> Void
  private var style: any StyleAdapter
  private var state = State()

  private func itemConfig(for item: MenuData.Item) -> MenuItemConfig {
    if let config = state.configs[item.id] {
      return config
    }
    let config = MenuItemConfig()
    state.configs[item.id] = config
    return config
  }

  private func itemRect(for targetItem: MenuData.Item) -> CGRect {
    state.layout.itemRects[targetItem.id] ?? .zero
  }

  private func itemView(for item: MenuData.Item) -> some View {
    switch item.kind {
    case .command(let command):
      AnyView(style.makeCommandLabel(command, config: itemConfig(for: item)))
    case .separator:
      AnyView(style.makeSeparator())
    case .submenu(let submenuData):
      AnyView(
        PopoverButton(
          content: { controller in
            Menu(
              data: submenuData,
              action: { command in
                controller.dismiss()
                action(command)
              },
              style: style,
            )
          },
          label: {
            AnyView(style.makeSubmenuLabel(submenuData, config: itemConfig(for: item)))
          },
        )
        .popoverPlacement(.after(alignment: .top))
        .popoverActivation(.pointerLinger)
      )
    }
  }

  private func tryActivate(item: MenuData.Item) {
    // Prevent subsequent activations.
    guard
      !state.activationLocked,
      !state.hasActivation,
      case .command(let command) = item.kind
    else { return }

    state.hasActivation = true
    let config = itemConfig(for: item)

    Task<Void, Never> {
      // TODO: Use a less hacky approach. Give MenuStyle more control over this animation.

      config.isActivated.toggle()
      try? await Task.sleep(for: .seconds(0.08))
      
      config.isActivated.toggle()
      try? await Task.sleep(for: .seconds(0.08))

      action(.command(command))

      state.hasActivation = false
    }
  }
}

extension Menu {
  public func menuStyle<Style: MenuStyle>(_ style: Style) -> Self {
    .init(
      data: data,
      action: action,
      style: DefaultStyleAdapter(style: style),
    )
  }
}

@MainActor
private protocol StyleAdapter {
  associatedtype CommandLabel: View
  associatedtype Separator: View
  associatedtype SubmenuLabel: View

  func computeLayout(for: MenuData) -> MenuLayout
  func makeCommandLabel(_: Command, config: MenuItemConfig) -> CommandLabel
  func makeSeparator() -> Separator
  func makeSubmenuLabel(_: MenuData, config: MenuItemConfig) -> SubmenuLabel
}

@MainActor
private final class DefaultStyleAdapter<Style: MenuStyle>: StyleAdapter {
  init(style: Style) {
    self.style = style
    cache = style.makeCache()
  }

  func computeLayout(for menuData: MenuData) -> MenuLayout {
    style.computeLayout(for: menuData, cache: &cache)
  }

  func makeCommandLabel(_ command: Command, config: MenuItemConfig) -> some View {
    style.makeCommandLabel(command, cache: cache, config: config)
  }

  func makeSeparator() -> some View {
    style.makeSeparator(cache: cache)
  }
  
  func makeSubmenuLabel(_ menuData: MenuData, config: MenuItemConfig) -> some View{
    style.makeSubmenuLabel(menuData, cache: cache, config: config)
  }

  let style: Style
  var cache: Style.Cache
}