import Foundation
import SparrowUICore

extension View {
  public func readScheduler(to value: Binding<CoreScheduler?>) -> some View {
    modifier(_ReadSchedulerModifier(value: value))
  }
}

@MainActor
public struct _ReadSchedulerModifier {
  var value: Binding<CoreScheduler?>
}

extension _ReadSchedulerModifier: ViewModifier {
  public typealias Body = Never
}

extension _ReadSchedulerModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    value.set(view.context.scheduler)
  }
}
