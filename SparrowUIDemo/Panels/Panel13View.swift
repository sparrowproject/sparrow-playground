import Foundation
import Observation
import SparrowUI
import SparrowUIFoundation

/// Modeling a menu system
struct Panel13View: PanelView {
  var body: some View {
    Group {
      backgroundColor

      Group {
        PopoverButton { controller in
          MenuContentView(menuData: menuData, onDismiss: { controller.dismiss() })
        } label: { config in
          showMenuButtonLabel(for: config, isShowing: .constant(false))
        }
        .popoverPlacement(.below(alignment: .trailing))
        .height(30)

        PopoverButton { controller in
          MenuContentView(menuData: menuData, onDismiss: { controller.dismiss() })
        } label: { config in
          showMenuButtonLabel(for: config, isShowing: .constant(false))
        } primaryAction: {
          print(">>> clicked!")
        }
        .popoverPlacement(.below(alignment: .trailing))
        .popoverActivation([.pointerLongPress, .pointerContextPress])
        .height(30)
        .offset(y: 40)

        showMenuButton
          .height(30)
          .offset(y: 80)
          .onPointerDown {
            $0.handled = locked
          }
          .onChange(of: showMenu) {
            if $0 {
              locked = true
            } else {
              Task { locked = showMenu }
            }
          }
          .popover(
            isPresented: $showMenu,
            preferredAnchor: .anchorTo(.bounds, place: .below(alignment: .trailing)),
            style: menuStyle,
          ) {
            MenuContentView(menuData: menuData, onDismiss: { showMenu = false })
          }
      }
      .width(130)
      .height(110)
      .alignment(.center)

      contextMenuTarget
        .offset(x: 50, y: 50)
        .contextPopover(style: menuStyle) { controller in
          MenuContentView(menuData: menuData, onDismiss: { controller.dismiss() })
        }
    }
  }

  @State private var showMenu = false
  @State private var locked = false

  private let menuData = MenuData(items: [
    .command(TestCommand(title: "New tab", keybinding: .newTab)),
    .command(TestCommand(title: "New window", keybinding: .newWindow)),
    .command(TestCommand(title: "New incognito window", keybinding: .newIncognitoWindow)),
    .separator(),
    .command(TestCommand(title: "History")),
    .command(TestCommand(title: "Downloads", keybinding: .downloads)),
    .command(TestCommand(title: "Bookmarks")),
    .command(TestCommand(title: "Extensions")),
    .command(TestCommand(title: "Delete browsing data...")),
    .command(TestCommand(title: "Zoom")),
    .separator(),
    .command(TestCommand(title: "Print...", keybinding: .print)),
    .command(TestCommand(title: "Translate...")),
    .submenu(.init(title: "Find and edit", items: [
      .command(TestCommand(title: "Find...", keybinding: .find)),
      .separator(),
      .command(TestCommand(title: "Cut", keybinding: .cut)),
      .command(TestCommand(title: "Copy", keybinding: .copy)),
      .command(TestCommand(title: "Paste", keybinding: .paste)),
    ])),
    .command(TestCommand(title: "Save and share")),
    .command(TestCommand(title: "More tools")),
    .separator(),
    .command(TestCommand(title: "Help")),
    .command(TestCommand(title: "Settings", keybinding: .settings)),
    .command(TestCommand(title: "Exit")),
  ])

  private var menuStyle: PopoverStyle {
    #if os(macOS)
    let backdropStyle = WindowBackdropStyle.material(.menu)
    #elseif os(Windows)
    let backdropStyle = WindowBackdropStyle.acrylic
    #endif
    return .init(
      backdropStyle: backdropStyle,
      borderStyle: .default,
      cornerStyle: .default,
    )
  }

  private var backgroundColor: Color {
    .init(light: .init(gray: 0.95), dark: .init(gray: 0.1))
  }

  private var showMenuButton: some View {
    Button {
      showMenu.toggle()
    } label: { config in
      showMenuButtonLabel(for: config, isShowing: $showMenu)
    }
  }

  private func showMenuButtonLabel(for config: ButtonConfig, isShowing: Binding<Bool>) -> some View {
    Group {
      RoundedRectangle(cornerRadius: 15)
        .fill(showMenuButtonColor(for: config, isShowing: isShowing.get()))

      Group {
        Text("Finish update")
          .font(.system(size: 12))
          .foregroundColor(.primaryText)
          .alignment(.leading)
        
        Symbol(source: menuSymbolSource)
          .tintColor(.primaryText)
          .alignment(.trailing)
      }
      .padding(.horizontal, 15)
    }
  }

  private var contextMenuTarget: some View {
    Group {
      Color.cyan.opacity(0.3)

      Text("Context click me!")
        .alignment(.center)
    }
    .width(200)
    .height(40)
  }

  private var menuSymbolSource: SymbolSource {
    #if os(macOS)
    .init(systemName: "ellipsis", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e700}", size: 12) // GlobalNavButton
    #endif
  }

  private func showMenuButtonColor(for config: ButtonConfig, isShowing: Bool) -> Color {
    let opacity: Double =
      if config.isPressed || isShowing {
        0.65
      } else if config.isHovered {
        0.5
      } else {
        0.35
      }

    return .blue.opacity(opacity)
  }
}

private struct MenuContentView: View {
  let menuData: MenuData
  let onDismiss: () -> Void

  var body: some View {
    Menu(data: menuData) { action in
      switch action {
      case .command(let command):
        print(">>> Command: \(command.title) selected!")
      }
      onDismiss()
    }
    .menuStyle(CustomMenuStyle())
  }
}

private struct CustomMenuStyle: MenuStyle {
  func makeCache() -> Void {}

  func computeLayout(for menuData: MenuData, cache: inout Void) -> MenuLayout {
    var labelWidths = [MenuData.Item.ID: CGFloat]()
    var accessoryWidths = [MenuData.Item.ID: CGFloat]()

    // First, measure all text elements.

    for item in menuData.items {
      switch item.kind {
      case .command(let command):
        labelWidths[item.id] = TextLineBuilder(
          text: command.title,
          font: .system(size: Metrics.itemFontSize),
        ).width
        if let keybindingString = command.keybinding?.description {
          accessoryWidths[item.id] = TextLineBuilder(
            text: keybindingString,
            font: .system(size: Metrics.itemFontSize),
          ).width
        }

      case .separator:
        break

      case .submenu(let submenuData):
        if let title = submenuData.title {
          labelWidths[item.id] = TextLineBuilder(
            text: title,
            font: .system(size: Metrics.itemFontSize),
          ).width
        }
        accessoryWidths[item.id] = 10
      }
    }

    // Next, compute max widths.

    let maxLabelWidth = labelWidths.values.max() ?? 0
    let maxAccessoryWidth = accessoryWidths.values.max() ?? 0

    // Then, we can compute total width & height.

    var totalWidth: CGFloat = 2 * Metrics.padding // insets
    totalWidth += 4 * Metrics.padding + maxLabelWidth // leading and trailing padding around the label
    if maxAccessoryWidth > 0 {
      totalWidth += maxAccessoryWidth + 2 * Metrics.padding // with leading padding
    }

    var totalHeight = 2 * Metrics.padding // insets
    for item in menuData.items {
      switch item.kind {
      case .command, .submenu:
        totalHeight += Metrics.itemHeight

      case .separator:
        totalHeight += 2 * Metrics.padding + Metrics.separatorHeight
      }
    }

    // Finally, we can compute the location of all items.

    var itemRects = [MenuData.Item.ID: CGRect]()
    var nextOffsetY = Metrics.padding
    for item in menuData.items {
      let itemHeight: CGFloat =
        switch item.kind {
        case .command, .submenu:
          Metrics.itemHeight
        case .separator:
          Metrics.separatorHeight + 2 * Metrics.padding
        }
      itemRects[item.id] = .init(
        x: Metrics.padding,
        y: nextOffsetY,
        width: totalWidth - 2 * Metrics.padding,
        height: itemHeight,
      )
      nextOffsetY += itemHeight
    }

    return .init(
      size: .init(width: totalWidth, height: totalHeight),
      itemRects: itemRects,
    )
  }

  func makeCommandLabel(_ command: Command, cache: Void, config: MenuItemConfig) -> some View {
    ItemView(
      title: { command.title },
      keybindingString: { command.keybinding?.description },
      isSubmenuItem: false,
      config: config,
    )
  }

  func makeSeparator(cache: Void) -> some View {
    Group {
      Color.primaryText
        .opacity(0.2)
        .height(Metrics.separatorHeight)
        .alignment(.center)
        .padding(.horizontal, 2 * Metrics.padding)
    }
    .height(2 * Metrics.padding + 1)
  }

  func makeSubmenuLabel(_ data: MenuData, cache: Void, config: MenuItemConfig) -> some View {
    ItemView(
      title: { data.title ?? "" },
      keybindingString: { nil },
      isSubmenuItem: true,
      config: config,
    )
  }

  private enum Metrics {
    static let itemHeight: CGFloat = 28
    static let separatorHeight: CGFloat = 1
    static let itemCornerRadius: CGFloat = 4
    static let itemFontSize: CGFloat = 12
    static let padding: CGFloat = 6
    static let submenuSymbolWidth: CGFloat = 7
  }

  private struct ItemView: View {
    let title: () -> String
    let keybindingString: () -> String?
    let isSubmenuItem: Bool
    let config: MenuItemConfig

    var body: some View {
      Group {
        RoundedRectangle(cornerRadius: Metrics.itemCornerRadius)
          .fill(itemBackgroundColor(for: config))

        Text(title())
          .font(.system(size: Metrics.itemFontSize))
          .foregroundColor(.primaryText)
          .alignment(.leading)
          .padding(.horizontal, 2 * Metrics.padding)
          .readSize(to: $titleSize)

        Text(keybindingString() ?? "")
          .font(.system(size: Metrics.itemFontSize))
          .foregroundColor(.primaryText.opacity(0.4))
          .alignment(.trailing)
          .padding(.horizontal, 2 * Metrics.padding)
          .readSize(to: $keybindingSize)
        
        Symbol(source: isSubmenuItem ? submenuSymbol : nil)
          .tintColor(.primaryText)
          .padding(.horizontal, 2 * Metrics.padding)
          .alignment(.trailing)
      }
      .width(containerWidth)
      .height(Metrics.itemHeight)
      .readAvailableSize(to: $availableSize)
      .onChange(of: computeMinWidth(), perform: {
        minWidth = $0
      })
    }

    @State private var titleSize = CGSize.zero
    @State private var keybindingSize = CGSize.zero
    @State private var availableSize = CGSize.zero
    @State private var minWidth: CGFloat = 0

    private var submenuSymbol: SymbolSource {
      #if os(macOS)
      .init(systemName: "chevron.right", size: 10)
      #elseif os(Windows)
      .init(glyph: "\u{e76c}", size: 10) // ChevronRight
      #endif
    }

    private var containerWidth: CGFloat {
      max(availableSize.width, minWidth)
    }

    private func computeMinWidth() -> CGFloat {
      titleSize.width
        + (keybindingSize.width > 0 ? keybindingSize.width + 2 * Metrics.padding : 0)
        + (isSubmenuItem ? Metrics.submenuSymbolWidth + 2 * Metrics.padding : 0)
        + 4 * Metrics.padding
    }

    private func itemBackgroundColor(for config: MenuItemConfig) -> Color {
      .black.opacity((config.isHovered && !config.isActivated) ? 0.1 : 0)
    }
  }
}

@Observable
final class TestCommand: Command {
  init(
    title: String,
    symbol: SymbolSource? = nil,
    keybinding: Keybinding? = nil,
  ) {
    self.title = title
    self.symbol = symbol
    self.keybinding = keybinding
  }

  var title: String
  var symbol: SymbolSource?
  var icon: ImageSource? { symbol.map { .symbol($0) } }
  var isHidden = false
  var isEnabled = true
  var isToggled = false
  var keybinding: Keybinding?
}

extension Keybinding {
  fileprivate static var newTab: Self {
    #if os(macOS)
    .init(keyEquivalent: "t", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .t, modifiers: [.control])
    #endif
  }

  fileprivate static var newWindow: Self {
    #if os(macOS)
    .init(keyEquivalent: "n", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .n, modifiers: [.control])
    #endif
  }

  fileprivate static var newIncognitoWindow: Self {
    #if os(macOS)
    .init(keyEquivalent: "n", modifiers: [.command, .shift])
    #elseif os(Windows)
    .init(virtualKey: .n, modifiers: [.control, .shift])
    #endif
  }

  fileprivate static var downloads: Self {
    #if os(macOS)
    .init(keyEquivalent: "l", modifiers: [.command, .option])
    #elseif os(Windows)
    .init(virtualKey: .j, modifiers: [.control])
    #endif
  }

  fileprivate static var print: Self {
    #if os(macOS)
    .init(keyEquivalent: "p", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .p, modifiers: [.control])
    #endif
  }

  fileprivate static var settings: Self? {
    #if os(macOS)
    .init(keyEquivalent: ",", modifiers: [.command])
    #elseif os(Windows)
    nil
    #endif
  }

  fileprivate static var find: Self {
    #if os(macOS)
    .init(keyEquivalent: "f", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .f, modifiers: [.control])
    #endif
  }

  fileprivate static var cut: Self {
    #if os(macOS)
    .init(keyEquivalent: "x", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .x, modifiers: [.control])
    #endif
  }

  fileprivate static var copy: Self {
    #if os(macOS)
    .init(keyEquivalent: "c", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .c, modifiers: [.control])
    #endif
  }

  fileprivate static var paste: Self {
    #if os(macOS)
    .init(keyEquivalent: "v", modifiers: [.command])
    #elseif os(Windows)
    .init(virtualKey: .v, modifiers: [.control])
    #endif
  }
}
