import CLevelDB
import Dispatch
import Foundation

/// A persistent String-to-Data store. Use one instance per directory.
/// All I/O runs on a private serial queue; construction does no I/O.
@MainActor
public final class BlobStore: Sendable {
  public enum StoreError: Error {
    case database(String)
    case invalidRecord
    case closed
  }

  public init(directory: URL, inlineThreshold: Int = 64 * 1024) {
    precondition(inlineThreshold >= 0)
    state = State(directory: directory, inlineThreshold: inlineThreshold)
  }

  /// Enqueues a write. Failures are retained and reported by `flush()` or `close()`.
  public func write(_ data: Data, forKey key: String) {
    write(data, forKey: key, codec: .data)
  }

  /// Enqueues encoding and writing together. Encoding failures are reported by
  /// flush/close, and leave any previous value intact. Threshold uses encoded size.
  public func write<Value: Sendable>(_ value: Value, forKey key: String, codec: BlobCodec<Value>) {
    queue.async { [state] in
      do {
        guard !state.isClosed else { throw StoreError.closed }
        try state.write(codec.encode(value), forKey: key)
      }
      catch { state.writeError = state.writeError ?? error }
    }
  }

  /// Returns nil for a missing key. Observes writes enqueued before this read.
  public func read(forKey key: String) async throws -> Data? {
    try await read(forKey: key, codec: .data)
  }

  /// Reads and decodes on the I/O queue. Missing keys do not invoke the codec.
  public func read<Value: Sendable>(forKey key: String, codec: BlobCodec<Value>) async throws -> Value? {
    try await withCheckedThrowingContinuation { continuation in
      queue.async { [state] in
        continuation.resume(with: Result {
          try state.read(forKey: key).map { try codec.decode($0) }
        })
      }
    }
  }

  /// Returns all indexed keys in UTF-8 byte order, including inline and external
  /// blobs. Observes writes enqueued before this call without reading blob files.
  public func enumerate() async throws -> [String] {
    try await withCheckedThrowingContinuation { continuation in
      queue.async { [state] in
        continuation.resume(with: Result { try state.enumerate() })
      }
    }
  }

  /// Loads every key/data pair in one queued operation, observing earlier writes.
  /// Holds all blobs in memory and throws if any record or blob cannot be read.
  public func readAll() async throws -> [String: Data] {
    try await readAll(codec: .data)
  }

  /// Reads and decodes each entry in one queued scan. Any decoding failure
  /// throws instead of returning partial results. All entries must use this codec.
  public func readAll<Value: Sendable>(codec: BlobCodec<Value>) async throws -> [String: Value] {
    try await withCheckedThrowingContinuation { continuation in
      queue.async { [state] in
        continuation.resume(with: Result { try state.readAll(codec: codec) })
      }
    }
  }

  /// Blocks until previously enqueued operations finish, then reports the first
  /// write failure since the last flush. Stop producers before flushing at exit.
  /// This waits for completed I/O; it is not a power-loss durability guarantee.
  public func flush() throws {
    // sync may run on the caller's thread, so this block must not perform I/O.
    try queue.sync {
      defer { state.writeError = nil }
      if let error = state.writeError { throw error }
    }
  }

  /// Drains pending operations and releases the database lock. Further I/O fails.
  public func close() throws {
    queue.async { [state] in state.close() }
    try flush()
  }

  private let queue = DispatchQueue(label: "SparrowStorage.BlobStore", qos: .utility)
  private let state: State

  deinit {
    queue.async { [state] in state.close() }
  }

  // All mutable state and LevelDB handles are confined to the store's queue.
  private final class State: @unchecked Sendable {
    let directory: URL
    let inlineThreshold: Int
    var database: OpaquePointer?
    var isClosed = false
    var writeError: (any Error)? {
      didSet {
        print(">>> writeError set to: \(String(describing: writeError))")
      }
    }

    init(directory: URL, inlineThreshold: Int) {
      self.directory = directory
      self.inlineThreshold = inlineThreshold
    }

    var blobsDirectory: URL { directory.appendingPathComponent("blobs", isDirectory: true) }

    func open() throws -> OpaquePointer {
      guard !isClosed else { throw StoreError.closed }
      if let database { return database }
      try FileManager.default.createDirectory(at: blobsDirectory, withIntermediateDirectories: true)
      let options = leveldb_options_create()!
      defer { leveldb_options_destroy(options) }
      leveldb_options_set_create_if_missing(options, 1)
      var error: UnsafeMutablePointer<CChar>?
      let handle = leveldb_open(options, directory.appendingPathComponent("index").path, &error)
      try check(error)
      guard let handle else { throw StoreError.database("Unable to open database") }
      database = handle
      return handle
    }

    func close() {
      if let database { leveldb_close(database) }
      database = nil
      isClosed = true
    }

    // Versioned records: [version, storage kind, payload]. Inline payloads may
    // be empty. External payloads contain a validated UUID, never a caller path.
    func record(forKey key: String) throws -> Data? {
      let database = try open()
      let options = leveldb_readoptions_create()!
      defer { leveldb_readoptions_destroy(options) }
      var error: UnsafeMutablePointer<CChar>?
      var length = 0
      let value = key.withCString {
        leveldb_get(database, options, $0, key.utf8.count, &length, &error)
      }
      defer { if let value { leveldb_free(value) } }
      try check(error)
      guard let value else { return nil }
      return Data(bytes: value, count: length)
    }

    func externalURL(_ record: Data) throws -> URL? {
      guard record.count >= 2, record[0] == 1, record[1] <= 1 else {
        throw StoreError.invalidRecord
      }
      guard record[1] == 1 else { return nil }
      guard let name = String(data: record.dropFirst(2), encoding: .utf8),
        let uuid = UUID(uuidString: name)
      else { throw StoreError.invalidRecord }
      return blobsDirectory.appendingPathComponent(uuid.uuidString)
    }

    func read(forKey key: String) throws -> Data? {
      guard let record = try record(forKey: key) else { return nil }
      return try data(from: record)
    }

    func data(from record: Data) throws -> Data {
      if let url = try externalURL(record) { return try Data(contentsOf: url) }
      return Data(record.dropFirst(2))
    }

    func enumerate() throws -> [String] {
      var keys: [String] = []
      try forEachEntry { key, _ in keys.append(key) }
      return keys
    }

    func readAll<Value: Sendable>(codec: BlobCodec<Value>) throws -> [String: Value] {
      var values: [String: Value] = [:]
      try forEachEntry { key, iterator in
        var length = 0
        let bytes = leveldb_iter_value(iterator, &length)
        let record = Data(UnsafeRawBufferPointer(start: bytes, count: length))
        values[key] = try codec.decode(data(from: record))
      }
      return values
    }

    private func forEachEntry(_ body: (String, OpaquePointer) throws -> Void) throws {
      let database = try open()
      let options = leveldb_readoptions_create()!
      defer { leveldb_readoptions_destroy(options) }
      leveldb_readoptions_set_fill_cache(options, 0)
      let iterator = leveldb_create_iterator(database, options)!
      defer { leveldb_iter_destroy(iterator) }

      leveldb_iter_seek_to_first(iterator)
      while leveldb_iter_valid(iterator) != 0 {
        var length = 0
        let bytes = leveldb_iter_key(iterator, &length)
        guard let key = String(
          bytes: UnsafeRawBufferPointer(start: bytes, count: length), encoding: .utf8
        ) else { throw StoreError.invalidRecord }
        try body(key, iterator)
        leveldb_iter_next(iterator)
      }
      var error: UnsafeMutablePointer<CChar>?
      leveldb_iter_get_error(iterator, &error)
      try check(error)
    }

    func write(_ data: Data, forKey key: String) throws {
      let database = try open()
      let previous = try record(forKey: key)
      let previousURL = try previous.flatMap { try externalURL($0) }
      var newURL: URL?
      var value = Data([1, 0])
      if data.count > inlineThreshold {
        let name = UUID().uuidString
        let url = blobsDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        newURL = url
        value = Data([1, 1]) + Data(name.utf8)
      } else {
        value.append(data)
      }

      let options = leveldb_writeoptions_create()!
      defer { leveldb_writeoptions_destroy(options) }
      // Persist the index before retiring the previous external file.
      leveldb_writeoptions_set_sync(options, 1)
      var error: UnsafeMutablePointer<CChar>?
      key.withCString { keyBytes in
        value.withUnsafeBytes { bytes in
          leveldb_put(database, options, keyBytes, key.utf8.count,
            bytes.baseAddress!.assumingMemoryBound(to: CChar.self), bytes.count, &error)
        }
      }
      // An I/O failure may have an ambiguous commit outcome. Keep the new
      // file so an index entry that did commit never points to a deleted blob.
      try check(error)
      if let previousURL, previousURL != newURL {
        try FileManager.default.removeItem(at: previousURL)
      }
    }

    func check(_ error: UnsafeMutablePointer<CChar>?) throws {
      if let error {
        defer { leveldb_free(error) }
        throw StoreError.database(String(cString: error))
      }
    }
  }
}
