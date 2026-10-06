import Foundation
import SparrowUICore
import SparrowUIFoundation

extension View {
  public func readPosition(in coordinateSpace: ReadPositionCoordinateSpace, to value: Binding<CGPoint?>) -> some View {
    modifier(_ReadPositionModifier(coordinateSpace: coordinateSpace, callback: { value.set($0) }))
  }

  public func readPosition(in coordinateSpace: ReadPositionCoordinateSpace, callback: @MainActor @escaping (CGPoint?) -> Void) -> some View {
    modifier(_ReadPositionModifier(coordinateSpace: coordinateSpace, callback: callback))
  }
}

@MainActor
public struct _ReadPositionModifier {
  let coordinateSpace: ReadPositionCoordinateSpace
  let callback: @MainActor (CGPoint?) -> Void
}

extension _ReadPositionModifier: ViewModifier {
  public typealias Body = Never
}

extension _ReadPositionModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    let getter = view.globalPositionGetter
    view.onChange(of: getter, perform: callback, cancellable: false)
  }
}

public enum ReadPositionCoordinateSpace {
  /// The position relative to the hosting view.
  case host
}