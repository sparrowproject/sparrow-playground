import Foundation
import SparrowDesignSystem
import SparrowSpaces
import SparrowTabs
import SparrowUI

struct SpaceChipView: View {
  enum Action {
    case clicked
    case command(SpaceChipCommand.ID)
  }

  let viewModel: SpaceChipViewModel
  let action: (Action) -> Void

  var body: some View {
    PopoverButton(
      content: { controller in
        SpaceChipContextMenuView(menuData: viewModel.contextMenuData) {
          controller.dismiss()
          action(.command($0))
        }
      },
      label: { config in
        Group {
          RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius)
            .fill(.gray.opacity(0.5))

          RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius)
            .fill(fillColor)

          plusIcon
            .alignment(.center)
            .opacity((viewModel.groupID == nil && config.isHovered) ? 1 : 0)

          IfLet(viewModel.groupModel) {
            groupDetail(for: $0)
              .alignment(.center)
          }
        }
        .opacity(opacity(for: config))
        .overlay(
          badgeView
            .opacity(config.isHovered ? 1 : 0)
        )
      },
      primaryAction: {
        action(.clicked)     
      },
    )
    .popoverActivation([.pointerContextPress])
  }

  private enum Metrics {
    static let badgeSize: CGFloat = 14
  }

  private var plusIcon: some View {
    Symbol(source: .newSpace)
      .tintColor(.primaryText.opacity(viewModel.isDragging() ? 0 : 0.4))
  }

  private var badgeView: some View {
    Group {
      Symbol(source: .jumpTo)
        .tintColor(.primaryText.opacity(viewModel.groupIsOpenInAnotherWindow ? 1 : 0))
        .alignment(.center)
    }
    .width(Metrics.badgeSize)
    .height(Metrics.badgeSize)
    .alignment(.topTrailing)
  }

  private var fillColor: Color {
    if !viewModel.hideSpace, viewModel.hasSpace {
      .primaryBackground
    } else {
      .clear
    }
  }

  private func opacity(for config: ButtonConfig) -> Double {
    if config.isPressed {
      0.7
    } else if !viewModel.hideSpace, viewModel.isSelected {
      1.0
    } else if config.isHovered {
      0.9
    } else {
      0.5
    }
  }

  private func groupDetail(for groupModel: TabGroupModel) -> some View {
    Image(source: groupModel.selectedTabModel.favicon ?? StandardImages.defaultFavicon)
      .resizable()
      .tintColor(groupModel.selectedTabModel.favicon == nil ? .primaryText.opacity(0.4) : nil)
      .width(StandardMetrics.iconSize)
      .height(StandardMetrics.iconSize)
      .opacity(viewModel.hideSpace ? 0 : 1)
  }
}

extension SymbolSource {
  fileprivate static var newSpace: SymbolSource {
    #if os(macOS)
    .init(systemName: "plus", size: 18)
    #elseif os(Windows)
    .init(glyph: "\u{e710}", size: 18) // Add
    #endif
  }

  fileprivate static var jumpTo: SymbolSource {
    #if os(macOS)
    .init(systemName: "arrow.up.forward.app", size: 12)
    #elseif os(Windows)
    .init(glyph: "\u{e8a7}", size: 18) // OpenInNewWindow
    #endif
  }
}
