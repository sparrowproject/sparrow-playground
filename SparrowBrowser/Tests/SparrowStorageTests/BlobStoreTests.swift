import Dispatch
import Foundation
import SparrowStorage

@main
struct BlobStoreTests {
  static func main() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let directory = root.appendingPathComponent("store")
    let store = BlobStore(directory: directory, inlineThreshold: 4)
    precondition(!FileManager.default.fileExists(atPath: directory.path), "Initialization must be lazy")
    let emptyValues = try await store.readAll()
    precondition(emptyValues.isEmpty)
    let emptyKeys = try await store.enumerate()
    precondition(emptyKeys.isEmpty)
    let missing = try await store.read(forKey: "missing")
    precondition(missing == nil)

    let keys = ["", "nul\0key", "路径/../🔑"]
    for key in keys {
      store.write(Data(), forKey: key)
      let value = try await store.read(forKey: key)
      precondition(value == Data())
    }
    store.write(Data([0, 1, 2, 3]), forKey: "boundary")
    try store.flush()
    try expectBlobCount(directory, 0)

    let large = Data(repeating: 42, count: 128)
    store.write(large, forKey: "large")
    let value = try await store.read(forKey: "large")
    precondition(value == large, "Reads must observe queued writes")
    try expectBlobCount(directory, 1)
    store.write(Data(repeating: 7, count: 256), forKey: "large")
    try store.flush()
    try expectBlobCount(directory, 1)
    store.write(Data([9]), forKey: "large")
    try store.flush()
    try expectBlobCount(directory, 0)

    for i in 0..<100 { store.write(Data(String(i).utf8), forKey: "ordered") }
    store.write(large, forKey: "persisted")
    var expectedValues = Dictionary(uniqueKeysWithValues: keys.map { ($0, Data()) })
    expectedValues["boundary"] = Data([0, 1, 2, 3])
    expectedValues["large"] = Data([9])
    expectedValues["ordered"] = Data("99".utf8)
    expectedValues["persisted"] = large
    let allValues = try await store.readAll()
    precondition(allValues == expectedValues, "readAll must observe queued writes and load all blob types")
    let expectedKeys = ["", "boundary", "large", "nul\0key", "ordered", "persisted", "路径/../🔑"]
    let enumerated = try await store.enumerate()
    precondition(enumerated == expectedKeys, "Enumeration must observe queued writes and return each key once")
    try store.close()
    let reopened = BlobStore(directory: directory)
    let reopenedValues = try await reopened.readAll()
    precondition(reopenedValues == expectedValues, "readAll must load persisted values")
    let reopenedKeys = try await reopened.enumerate()
    precondition(reopenedKeys == expectedKeys, "Enumeration must include persisted inline and external keys")
    let ordered = try await reopened.read(forKey: "ordered")
    let persisted = try await reopened.read(forKey: "persisted")
    precondition(ordered == Data("99".utf8))
    precondition(persisted == large)
    for key in keys {
      let value = try await reopened.read(forKey: key)
      precondition(value == Data())
    }
    let blobFiles = try FileManager.default.contentsOfDirectory(
      at: directory.appendingPathComponent("blobs"), includingPropertiesForKeys: nil
    )
    precondition(blobFiles.count == 1)
    try FileManager.default.removeItem(at: blobFiles[0])
    do {
      _ = try await reopened.readAll()
      preconditionFailure("readAll must throw for a missing external blob")
    } catch {}
    try reopened.close()
    do {
      _ = try await reopened.readAll()
      preconditionFailure("readAll after close must fail")
    } catch BlobStore.StoreError.closed {}
    do {
      _ = try await reopened.read(forKey: "ordered")
      preconditionFailure("Reads after close must fail")
    } catch BlobStore.StoreError.closed {}
    do {
      _ = try await reopened.enumerate()
      preconditionFailure("Enumeration after close must fail")
    } catch BlobStore.StoreError.closed {}

    let blocked = root.appendingPathComponent("file")
    try Data([0]).write(to: blocked)
    let broken = BlobStore(directory: blocked)
    do {
      _ = try await broken.readAll()
      preconditionFailure("readAll must report database open failures")
    } catch {}
    do {
      _ = try await broken.enumerate()
      preconditionFailure("Enumeration must report database open failures")
    } catch {}
    broken.write(large, forKey: "failure")
    do {
      try broken.flush()
      preconditionFailure("Flush must report background write failures")
    } catch {}
    try broken.close()
    try await testCodecs(root)
    await testCachingWebHistory()
    #if os(macOS)
    try await testPersistentWebHistory(root)
    #endif
    print("BlobStore tests passed")
  }

  struct Payload: Sendable, Equatable {
    let text: String
  }

  enum CodecError: Error { case encode, decode }

  @MainActor
  static func testCodecs(_ root: URL) async throws {
    let codec = BlobCodec<Payload>(
      encode: { value in
        dispatchPrecondition(condition: .notOnQueue(.main))
        precondition(!Thread.isMainThread)
        return Data(value.text.utf8)
      },
      decode: { data in
        dispatchPrecondition(condition: .notOnQueue(.main))
        precondition(!Thread.isMainThread)
        return Payload(text: String(decoding: data, as: UTF8.self))
      }
    )
    let directory = root.appendingPathComponent("codecs")
    let store = BlobStore(directory: directory, inlineThreshold: 4)
    let small = Payload(text: "tiny")
    let large = Payload(text: String(repeating: "x", count: 128))
    let empty = try await store.readAll(codec: codec)
    precondition(empty.isEmpty)
    store.write(small, forKey: "small", codec: codec)
    store.write(large, forKey: "large", codec: codec)
    try store.flush()
    try expectBlobCount(directory, 1)
    let raw = try await store.read(forKey: "small")
    precondition(raw == Data("tiny".utf8), "Codec must determine stored bytes")
    let decoded = try await store.read(forKey: "large", codec: codec)
    precondition(decoded == large)
    store.write(Payload(text: "new"), forKey: "small", codec: codec)
    let all = try await store.readAll(codec: codec)
    precondition(all == ["small": Payload(text: "new"), "large": large])

    let failing = BlobCodec<Payload>(
      encode: { _ in throw CodecError.encode },
      decode: { _ in throw CodecError.decode }
    )
    store.write(small, forKey: "large", codec: failing)
    do {
      try store.flush()
      preconditionFailure("Flush must report encoding errors")
    } catch CodecError.encode {}
    try store.flush()
    let preserved = try await store.read(forKey: "large", codec: codec)
    precondition(preserved == large, "Failed encoding must preserve previous value")
    let missing = try await store.read(forKey: "missing", codec: failing)
    precondition(missing == nil, "Missing keys must not be decoded")
    do {
      _ = try await store.read(forKey: "small", codec: failing)
      preconditionFailure("Read must report decoding errors")
    } catch CodecError.decode {}
    do {
      _ = try await store.readAll(codec: failing)
      preconditionFailure("readAll must report decoding errors")
    } catch CodecError.decode {}
    store.write(small, forKey: "small", codec: failing)
    do {
      try store.close()
      preconditionFailure("Close must report encoding errors")
    } catch CodecError.encode {}
    let reopened = BlobStore(directory: directory)
    let persisted = try await reopened.readAll(codec: codec)
    precondition(persisted == all)
    try reopened.close()
    reopened.write(small, forKey: "closed", codec: failing)
    do {
      try reopened.flush()
      preconditionFailure("Closed stores must reject writes before encoding")
    } catch BlobStore.StoreError.closed {}

    let jsonStore = BlobStore(directory: root.appendingPathComponent("json"))
    let model = Model(name: "example", count: 42)
    jsonStore.write(model, forKey: "model", codec: .json)
    let jsonValue = try await jsonStore.read(forKey: "model", codec: BlobCodec<Model>.json)
    precondition(jsonValue == model)
    let jsonValues = try await jsonStore.readAll(codec: BlobCodec<Model>.json)
    precondition(jsonValues == ["model": model])
    try jsonStore.close()
  }

  struct Model: Codable, Sendable, Equatable {
    let name: String
    let count: Int
  }

  static func expectBlobCount(_ directory: URL, _ expected: Int) throws {
    let count = try FileManager.default.contentsOfDirectory(
      at: directory.appendingPathComponent("blobs"), includingPropertiesForKeys: nil
    ).count
    precondition(count == expected, "Expected \(expected) external blobs, got \(count)")
  }
}
