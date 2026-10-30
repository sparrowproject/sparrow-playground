import Observation

#if os(macOS)
import AppKit
#endif

@MainActor
public final class CoreScheduler {
  public init() {}

  public static var currentAnimation: CoreViewAnimation? {
    get {
      currentAnimationInstance()?.animation
    }
    set {
      assert(newValue == nil || currentAnimationInstance() != nil)
      currentAnimationInstance()?.animation = newValue
    }
  }

  @discardableResult
  public static func withAnimation<R>(_ animation: CoreViewAnimation?, _ body: () -> R) -> R {
    animationInstanceStack.append(animation.flatMap { .init(animation: $0) })
    let result = body()
    animationInstanceStack.removeLast()
    return result
  }

  public func scheduleUpdate(perform work: @MainActor @escaping () -> Void) {
    let workItem = WorkItem(animationInstance: Self.currentAnimationInstance(), work: work)
    updateQueue.append(workItem)
    scheduleUpdateTaskIfNeeded()
  }

  public func scheduleDeferredUpdate(perform work: @MainActor @escaping () -> Void) {
    let workItem = WorkItem(animationInstance: Self.currentAnimationInstance(), work: work)
    deferredUpdateQueue.append(workItem)
    scheduleUpdateTaskIfNeeded()
  }

  public func flushUpdates() {
    guard !updateQueue.isEmpty || !deferredUpdateQueue.isEmpty else { return }

    defer { animationInstance = nil }

    #if os(macOS)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    defer { CATransaction.commit() }
    #endif

    func processWorkItems(_ items: [WorkItem]) {
      for item in items {
        animationInstance = item.animationInstance

        // Make sure any resulting mutations pick up the same animation instance by default.
        Self.animationInstanceStack.append(animationInstance)
        item.work()
        Self.animationInstanceStack.removeLast()
      }
    }

    while !updateQueue.isEmpty {
      let items = updateQueue
      updateQueue = []
      processWorkItems(items)
    }

    while !deferredUpdateQueue.isEmpty {
      let items = deferredUpdateQueue
      deferredUpdateQueue = []
      processWorkItems(items)
    }

    for observer in updateObservers {
      observer()
    }
  }

  public func observeUpdates(_ observer: @MainActor @escaping () -> Void) {
    updateObservers.append(observer)
  }

  private(set) var animationInstance: CoreViewAnimationInstance?

  private static var animationInstanceStack: [CoreViewAnimationInstance?] = []

  private static func currentAnimationInstance() -> CoreViewAnimationInstance? {
    animationInstanceStack.last ?? nil
  }

  struct WorkItem {
    let animationInstance: CoreViewAnimationInstance?
    let work: () -> Void
  }

  private var updateTask: Task<Void, Never>?
  private var updateQueue: [WorkItem] = []
  private var deferredUpdateQueue: [WorkItem] = []
  private var updateObservers = [() -> Void]()

  private func scheduleUpdateTaskIfNeeded() {
    guard updateTask == nil else { return }
    updateTask = .init(priority: .userInitiated) {
      updateTask = nil
      flushUpdates()
    }
  }
}

extension CoreScheduler {
  public func onChange<Value>(
    of expression: @MainActor @escaping () -> Value,
    perform work: @MainActor @escaping (Value) -> Void,
    cancelWhen shouldCancel: @MainActor @escaping () -> Bool,
  ) {
    let rebind = { @Sendable [weak self] () -> Void in
      Task<Void, Never>.immediate { @MainActor [weak self] in
        self?.onChange(of: expression, perform: work, cancelWhen: shouldCancel)
      }
    }
    scheduleUpdate { [weak self] in
      guard self != nil, !shouldCancel() else { return }
      let latestValue = withObservationTracking(expression, onChange: rebind)
      work(latestValue)
    }
  }

  public func onChange<Value>(
    of expression: @MainActor @escaping () -> Value,
    performDeferred work: @MainActor @escaping (Value) -> Void,
    cancelWhen shouldCancel: @MainActor @escaping () -> Bool,
  ) {
    let rebind = { @Sendable [weak self] () -> Void in
      Task<Void, Never>.immediate { @MainActor [weak self] in
        self?.onChange(of: expression, performDeferred: work, cancelWhen: shouldCancel)
      }
    }
    scheduleDeferredUpdate { [weak self] in
      guard self != nil, !shouldCancel() else { return }
      let latestValue = withObservationTracking(expression, onChange: rebind)
      work(latestValue)
    }
  }
}
