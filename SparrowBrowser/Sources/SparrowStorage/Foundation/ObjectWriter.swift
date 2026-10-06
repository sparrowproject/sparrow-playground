import Foundation

@MainActor
final class ObjectWriter<T: Codable & Sendable & Equatable> {
  init(fileURL: URL) {
    self.fileURL = fileURL
    dispatchQueue = .init(label: "object-writer")
  }

  /// The current object data. Set this if the value from the file is already known.
  var currentObject: T?

  func write(_ obj: T) {
    pendingObject = obj

    pendingTask?.cancel()
    pendingTask = .init {
      try? await Task.sleep(for: .milliseconds(200))
      guard !Task.isCancelled else { return }

      // Avoid redundant writes.
      if pendingObject != currentObject {
        // print(">>> pendingObject: \(pendingObject) != currentObject: \(currentObject)")
        print(">>> writeObject, toFile: \(fileURL)")
        dispatchQueue.async { [pendingObject, fileURL] in
          writeObject(pendingObject, toFile: fileURL)
        }
        currentObject = pendingObject
      }

      pendingObject = nil
      pendingTask = nil
    }
  }

  func flush() {
    // If there is a pending object, then write it out now. Cancel any existing
    // task so it goes away gracefully.

    guard pendingObject != nil else { return }

    pendingTask?.cancel()
    pendingTask = nil

    dispatchQueue.sync { [pendingObject, fileURL] in
      writeObject(pendingObject, toFile: fileURL)
    }

    pendingObject = nil
  }

  func remove() {
    pendingTask?.cancel()
    pendingTask = nil

    dispatchQueue.async { [fileURL] in
      do {
        try FileManager.default.removeItem(at: fileURL)
      } catch {
        print(">>> error removing file: \(fileURL)")
      }
    }
  }

  private let fileURL: URL
  private let dispatchQueue: DispatchQueue
  private var pendingObject: T?
  private var pendingTask: Task<Void, Never>?
}

private func writeObject<T: Codable>(_ obj: T, toFile fileURL: URL) {
  print(">>> writeObject to: \(fileURL)")
  do {
    let encoder = JSONEncoder()
    let data = try encoder.encode(obj)
    try data.write(to: fileURL)
  } catch {
    print(">>> error writing object to file: \(fileURL), error: \(error)")
  }
}