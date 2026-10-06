import SparrowUICore

@MainActor
public func withAnimation(_ animation: CoreViewAnimation? = .default, _ body: () -> Void) {
  CoreScheduler.withAnimation(animation, body)
}
