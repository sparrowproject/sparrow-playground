#if os(Windows)
import WindowsFoundation

extension IAsyncOperationWithProgress {
  /// A concurrency safe variant of `IAsyncOperationWithProgress.get()`.
  @MainActor
  public var value: TResult {
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
