## SparrowStorage

This module provides storage for the rest of the system. Storage is layered
on top of other modules, either by observing state or by explicitly plugging
into and implementing bespoke persistence / backend interfaces.

# BlobStore

```swift
let store = BlobStore(directory: storageDirectory, inlineThreshold: 64 * 1024)
store.write(data, forKey: "thumbnail:123")
let cachedData = try await store.read(forKey: "thumbnail:123")
let keys = try await store.enumerate()
let allData = try await store.readAll()

// During termination, after stopping callers that enqueue writes:
try store.flush()
// Or use close() to also release the database lock.
```

Construction does no I/O. A dedicated serial DispatchQueue opens LevelDB lazily
and performs all reads, writes, cleanup, and closing. Writes retain their Data
until processed. Reads observe operations already enqueued; concurrent callers
are ordered by queue submission. Missing keys return nil; other read failures throw.

`enumerate()` returns all indexed keys in UTF-8 byte order, including inline and
external blobs, and observes previously enqueued writes. It scans the index on
the I/O queue without reading blob files. Enumeration failures throw.

`readAll()` returns a `[String: Data]` containing every key/data pair. It scans
LevelDB once, using inline values directly and loading external blob files on
the I/O queue. Writes cannot interleave with the load. All values are held in
memory; any invalid record, database error, or unreadable blob causes the whole
operation to throw rather than return partial results.

## Codecs

Pass a `BlobCodec<Value>` to store any `Sendable` value using custom byte
encoding, such as PNG for an image representation that supports background use:

```swift
let codec = BlobCodec<MyValue>(
  encode: { value in try value.encodedData() },
  decode: { data in try MyValue(encodedData: data) }
)
store.write(value, forKey: "item", codec: codec)
let item = try await store.read(forKey: "item", codec: codec)
let items = try await store.readAll(codec: codec)
```

`BlobCodec<MyModel>.json` supports `Codable & Sendable` models using fresh
default JSON encoders/decoders. `.data` passes Data through unchanged; the
original Data methods remain available without a codec argument.

Encoding and decoding run on the same I/O queue as storage. A write retains its
value until processed; encoding and writing form one queued operation. The
inline threshold applies to encoded bytes. `flush()` and `close()` wait for
encoding and report encoding failures alongside write failures. A failed encode
leaves the previous stored value intact. Decoding failures throw from reads;
missing keys return nil without invoking the decoder. Typed `readAll()` decodes
each entry during the scan and holds all decoded values in memory.

Codecs are supplied per operation, and their identity is not saved in the store.
Use a matching codec when reading; typed `readAll()` requires every entry to be
decodable with that codec. Codec closures and captured state must support use
off the main thread and concurrent use if shared between stores. Sendable values
must be safe to transfer; mutable reference values are not automatically copied
at the time of submission.

Values at or below the threshold are stored inline. Larger values are written
atomically to UUID-named files in `blobs/`, with versioned references in the
LevelDB `index/` directory. Replacement commits the new index value before
removing the previous file. Keys are UTF-8 bytes, including embedded NULs, and
are never used as filesystem paths.

`flush()` blocks the caller while the queue finishes all preceding operations.
It throws the first background write error since the previous flush and clears
that recorded error. Failed writes are not retried automatically. `close()` also
drains the queue and reports errors, then rejects subsequent reads and writes.
Use one live store per directory; close it before reopening the same directory.
Deinitialization enqueues cleanup but does not wait, so explicitly flush or close
before process termination.

This provides orderly shutdown completion, not a guarantee against power loss.
Interrupted writes or ambiguous database errors can leave unreferenced blob
files; automatic orphan collection is not implemented.
