import Foundation
import SparrowUICore

extension View {
  public func onChange<Value>(
    of expression: @autoclosure @MainActor @escaping () -> Value,
    perform work: @MainActor @escaping (Value) -> Void,
  ) -> some View {
    modifier(_OnChangeModifier<Value>(expression: expression, work: work))
  }
}

@MainActor
public struct _OnChangeModifier<Value> {
  let expression: @MainActor () -> Value
  let work: @MainActor (Value) -> Void
}

extension _OnChangeModifier: ViewModifier {
  public typealias Body = Never
}

extension _OnChangeModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onChange(of: expression, perform: work, cancellable: false)
  }
}
