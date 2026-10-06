import Foundation
import SparrowUICore

extension View {
  public func acceptsFocus(_ acceptsFocus: @autoclosure @MainActor @escaping () -> Bool = true) -> some View {
    modifier(_AcceptsFocusModifier(acceptsFocus: acceptsFocus))
  }
}

@MainActor
public struct _AcceptsFocusModifier {
  let acceptsFocus: @MainActor () -> Bool
}

extension _AcceptsFocusModifier: ViewModifier {
  public typealias Body = Never
}

extension _AcceptsFocusModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.acceptsFocus = acceptsFocus
  }
}
