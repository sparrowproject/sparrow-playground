#if os(Windows)
import WindowsFoundation

extension IAsyncAction {
  /// A concurrency safe variant of `IAsyncAction.get()`.
  @MainActor
  public var value: Void {
    get async throws {
      if status == .started {
        var observer: (@Sendable () -> Void)?
        completed = { _, _ in
          Task { @MainActor in
            observer?()
          }
        }
        await withCheckedContinuation { continuation in
          observer = {
            continuation.resume(returning: ())
          }
        }
      }
      return try getResults()
    }
  }
}

#endif
