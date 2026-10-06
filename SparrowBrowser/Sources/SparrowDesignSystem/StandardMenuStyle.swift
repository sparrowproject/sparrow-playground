import Foundation
import Observation
import SparrowUI

public struct StandardMenuStyle: MenuStyle {
  @Observable
  public final class LayoutCache {
    init() {}
    var hasIcons = false
  }

  public init() {}

  public func makeCache() -> LayoutCache {
    .init()
  }

  public func computeLayout(for menuData: MenuData, cache: inout LayoutCache) -> MenuLayout {
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
        if command.icon != nil {
          cache.hasIcons = true
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
    if cache.hasIcons {
      totalWidth += Metrics.iconSize + 2 * Metrics.padding // with spacing between icon and label
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

  public func makeCommandLabel(_ command: Command, cache: LayoutCache, config: MenuItemConfig) -> some View {
    ItemView(
      title: { command.title },
      icon: { command.icon },
      keybindingString: { command.keybinding?.description },
      isEnabled: { command.isEnabled },
      isSubmenuItem: false,
      cache: cache,
      config: config,
    )
  }

  public func makeSeparator(cache: LayoutCache) -> some View {
    Group {
      Color.primaryText
        .opacity(0.2)
        .height(Metrics.separatorHeight)
        .alignment(.center)
        .padding(.horizontal, 2 * Metrics.padding)
    }
    .height(2 * Metrics.padding + Metrics.separatorHeight)
  }

  public func makeSubmenuLabel(_ data: MenuData, cache: LayoutCache, config: MenuItemConfig) -> some View {
    ItemView(
      title: { data.title ?? "" },
      icon: { nil },
      keybindingString: { nil },
      isEnabled: { true },
      isSubmenuItem: true,
      cache: cache,
      config: config,
    )
  }

  private enum Metrics {
    static let itemHeight: CGFloat = 28
    static let itemCornerRadius: CGFloat = 4
    static let itemFontSize: CGFloat = 12
    static let iconSize: CGFloat = 16
    static let separatorHeight: CGFloat = 1
    static let padding: CGFloat = 6
    static let submenuSymbolWidth: CGFloat = 7
  }

  private struct ItemView: View {
    let title: () -> String
    let icon: () -> ImageSource?
    let keybindingString: () -> String?
    let isEnabled: () -> Bool
    let isSubmenuItem: Bool
    let cache: LayoutCache
    let config: MenuItemConfig

    var body: some View {
      Group {
        RoundedRectangle(cornerRadius: Metrics.itemCornerRadius)
          .fill(itemBackgroundColor(for: config))

        Image(source: icon())
          .resizable()
          .width(Metrics.iconSize)
          .height(Metrics.iconSize)
          .alignment(.leading)
          .offset(x: 2 * Metrics.padding)

        Text(title())
          .font(.system(size: Metrics.itemFontSize))
          .foregroundColor(.primaryText.opacity(isEnabled() ? 1 : 0.4))
          .readSize(to: $titleSize)
          .alignment(.leading)
          .offset(x: 2 * Metrics.padding + (cache.hasIcons ? Metrics.iconSize + 2 * Metrics.padding : 0))

        Text(keybindingString() ?? "")
          .font(.system(size: Metrics.itemFontSize))
          .foregroundColor(.primaryText.opacity(0.4))
          .alignment(.trailing)
          .padding(.horizontal, 2 * Metrics.padding)
          .readSize(to: $keybindingSize)
        
        Symbol(source: isSubmenuItem ? StandardSymbols.forward : nil)
          .tintColor(.primaryText.opacity(isEnabled() ? 1 : 0.4))
          .padding(.horizontal, 2 * Metrics.padding)
          .alignment(.trailing)
      }
    }

    @State private var titleSize = CGSize.zero
    @State private var keybindingSize = CGSize.zero

    private func itemBackgroundColor(for config: MenuItemConfig) -> Color {
      .black.opacity((config.isHovered && !config.isActivated && isEnabled()) ? 0.1 : 0)
    }
  }
}
