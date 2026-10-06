import SparrowUICore
import SparrowUIFoundation

extension View {
  public func colorScheme(_ colorScheme: @autoclosure @MainActor @escaping () -> ColorScheme?) -> some View {
    modifier(_ColorSchemeModifier(colorScheme: colorScheme))
  }
}

@MainActor
public struct _ColorSchemeModifier {
  let colorScheme: @MainActor () -> ColorScheme?
}

extension _ColorSchemeModifier: ViewModifier {
  public typealias Body = Never
}

extension _ColorSchemeModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.colorScheme = colorScheme
  }
}
