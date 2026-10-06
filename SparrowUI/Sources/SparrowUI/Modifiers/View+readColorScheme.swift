import Foundation
import SparrowUICore
import SparrowUIFoundation

extension View {
  public func readColorScheme(to value: Binding<ColorScheme>) -> some View {
    modifier(_ReadColorSchemeModifier(value: value))
  }
}

@MainActor
public struct _ReadColorSchemeModifier {
  var value: Binding<ColorScheme>
}

extension _ReadColorSchemeModifier: ViewModifier {
  public typealias Body = Never
}

extension _ReadColorSchemeModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    let context = view.context // Avoid retaining `view` in these closures.
    view.onChange(of: { context.colorScheme }, perform: { value.set($0) }, cancellable: false)
  }
}
