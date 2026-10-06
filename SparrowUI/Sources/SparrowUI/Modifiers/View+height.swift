import Foundation
import SparrowUICore

extension View {
  public func height(_ height: @autoclosure @MainActor @escaping () -> CGFloat) -> some View {
    modifier(_HeightModifier(height: height))
  }
}

@MainActor
public struct _HeightModifier {
  var height: @MainActor () -> CGFloat
}

extension _HeightModifier: ViewModifier {
  public typealias Body = Never
}

extension _HeightModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.height = height
  }
}
