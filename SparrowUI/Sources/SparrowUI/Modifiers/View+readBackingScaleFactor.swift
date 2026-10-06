import Foundation
import SparrowUICore
import SparrowUIFoundation

extension View {
  public func readBackingScaleFactor(to value: Binding<CGFloat>) -> some View {
    modifier(_ReadBackingScaleFactorModifier(value: value))
  }
}

@MainActor
public struct _ReadBackingScaleFactorModifier {
  var value: Binding<CGFloat>
}

extension _ReadBackingScaleFactorModifier: ViewModifier {
  public typealias Body = Never
}

extension _ReadBackingScaleFactorModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    let context = view.context // Avoid retaining `view` in these closures.
    view.onChange(of: { context.backingScaleFactor }, perform: { value.set($0) }, cancellable: false)
  }
}
