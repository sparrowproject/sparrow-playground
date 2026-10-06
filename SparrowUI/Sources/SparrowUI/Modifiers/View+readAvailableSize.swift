import Foundation
import SparrowUICore
import SparrowUIFoundation

extension View {
  public func readAvailableSize(to value: Binding<CGSize>) -> some View {
    modifier(_ReadAvailableSizeModifier(value: value))
  }
}

@MainActor
public struct _ReadAvailableSizeModifier {
  var value: Binding<CGSize>
}

extension _ReadAvailableSizeModifier: ViewModifier {
  public typealias Body = Never
}

extension _ReadAvailableSizeModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.observeAvailableSize { value.set($0) }
  }
}
