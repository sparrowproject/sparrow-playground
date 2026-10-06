import SparrowUICore

extension View {
  public func allowsHitTesting(_ allowsHitTesting: @autoclosure @MainActor @escaping () -> Bool = true) -> some View {
    modifier(_AllowsHitTestingModifier(allowsHitTesting: allowsHitTesting))
  }
}

@MainActor
public struct _AllowsHitTestingModifier {
  let allowsHitTesting: @MainActor () -> Bool
}

extension _AllowsHitTestingModifier: ViewModifier {
  public typealias Body = Never
}

extension _AllowsHitTestingModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.allowsHitTesting = allowsHitTesting
  }
}
