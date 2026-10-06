@MainActor
public protocol StorageComponent {
  typealias ShutdownTask = Task<Void, Never>

  /// Completes any pending IO, making it safe to exit the app without data loss.
  /// Optionally returns a `Task` if shutdown cannot be completed synchronously.
  func shutdown() -> ShutdownTask?
}