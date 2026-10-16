import SparrowUICore

@MainActor
@discardableResult
public func withAnimation<R>(_ animation: CoreViewAnimation? = .default, _ body: () -> R) -> R {
  CoreScheduler.withAnimation(animation, body)
}
