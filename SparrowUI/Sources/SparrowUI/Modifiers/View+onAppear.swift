import Foundation
import SparrowUICore

extension View {
  public func onAppear(
    perform work: @MainActor @escaping () -> Void,
  ) -> some View {
    modifier(_OnAppearModifier(work: work))
  }
}

@MainActor
public struct _OnAppearModifier {
  let work: @MainActor () -> Void
}

extension _OnAppearModifier: ViewModifier {
  public typealias Body = Never
}

extension _OnAppearModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.onAppear(perform: work)
  }
}
