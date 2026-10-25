import Foundation
import Observation
import SparrowHistory
import SparrowStorageBase

public typealias TypedHistoryStoreDependencies
  = TypedHistoryProviding
  & StoragePathsProviding

@MainActor
final class TypedHistoryStore: StorageComponent {
  init(dependencies: TypedHistoryStoreDependencies) {
    self.dependencies = dependencies
  }

  func initialize() async {
    let records = await readRecords()
    objectWriter.currentObject = records
    for record in records {
      dependencies.typedHistory.storeRecord(record)
    }
    observationTask = .init(operation: observeRecords)
  }

  func shutdown() -> ShutdownTask? {
    observationTask?.cancel()
    observationTask = nil

    objectWriter.write(Array(dependencies.typedHistory.model.records.values))
    objectWriter.flush()
    return nil
  }

  private let dependencies: TypedHistoryStoreDependencies
  private var observationTask: Task<Void, Never>?

  private lazy var storagePath = dependencies.storagePaths.userDataDirectory.appendingPathComponent("typed-history.json")
  private lazy var objectWriter = ObjectWriter<[TypedHistoryRecord]>(fileURL: storagePath)

  private func readRecords() async -> [TypedHistoryRecord] {
    await withCheckedContinuation { continuation in
      DispatchQueue(label: "typed-history-reader").async { [storagePath] in
        var records = [TypedHistoryRecord]()
        do {
          let data = try Data(contentsOf: storagePath)
          records = try JSONDecoder().decode([TypedHistoryRecord].self, from: data)
        } catch {
          if (error as NSError).code != NSFileReadNoSuchFileError {
            print(">>> error reading typed history: \(error)")
          }
        }
        continuation.resume(returning: records)
      }
    }
  }

  private func observeRecords() async {
    let model = dependencies.typedHistory.model
    for await records in Observations({ [model] in
      Array(model.records.values)
    }) {
      guard !Task.isCancelled else { return }
      objectWriter.write(records)
    }
  }
}
