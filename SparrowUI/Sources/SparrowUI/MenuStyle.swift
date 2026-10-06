import SparrowUIFoundation

@MainActor
public protocol MenuStyle {
  associatedtype CommandLabel: View
  associatedtype Separator: View
  associatedtype SubmenuLabel: View
  associatedtype Cache
  // associatedtype CustomBody: View

  func makeCache() -> Cache
  func computeLayout(for: MenuData, cache: inout Cache) -> MenuLayout

  func makeCommandLabel(_: Command, cache: Cache, config: MenuItemConfig) -> CommandLabel
  func makeSeparator(cache: Cache) -> Separator
  func makeSubmenuLabel(_: MenuData, cache: Cache, config: MenuItemConfig) -> SubmenuLabel
  // func makeCustom(view: AnyView, config: MenuItemConfig) -> CustomBody
}

struct _BlankMenuStyle: MenuStyle {
  func makeCache() -> Void {}

  func computeLayout(for: MenuData, cache: inout Void) -> MenuLayout {
    .init()
  }

  func makeCommandLabel(_ command: Command, cache: Void, config _: MenuItemConfig) -> some View {
    Color.clear
  }

  func makeSeparator(cache: Void) -> some View {
    Color.clear
  }

  func makeSubmenuLabel(_ data: MenuData, cache: Void, config: MenuItemConfig) -> some View {
    Color.clear
  }

  // func makeCustom(view: AnyView, config: MenuItemConfig) -> some View {
  //   view
  // }
}
