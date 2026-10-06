import Foundation
import SparrowUICore
import SparrowUIFoundation

extension View {
  public func readSize(to value: Binding<CGSize>) -> some View {
    modifier(_ReadSizeModifier(callback: { value.set($0) }))
  }

  public func readSize(callback: @MainActor @escaping (CGSize) -> Void) -> some View {
    modifier(_ReadSizeModifier(callback: callback))
  }
}

@MainActor
public struct _ReadSizeModifier {
  var callback: @MainActor (CGSize) -> Void
}

extension _ReadSizeModifier: ViewModifier {
  public typealias Body = Never
}

extension _ReadSizeModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.observeSize(callback)
  }
}
