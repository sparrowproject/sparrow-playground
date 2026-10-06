import Foundation

/// Converts values to and from stored bytes. BlobStore invokes these closures
/// on its I/O queue. Captured state must be safe to use across threads/stores.
public struct BlobCodec<Value: Sendable>: Sendable {
  public let encode: @Sendable (Value) throws -> Data
  public let decode: @Sendable (Data) throws -> Value

  public init(
    encode: @escaping @Sendable (Value) throws -> Data,
    decode: @escaping @Sendable (Data) throws -> Value
  ) {
    self.encode = encode
    self.decode = decode
  }
}

extension BlobCodec where Value == Data {
  public static var data: Self {
    Self(encode: { $0 }, decode: { $0 })
  }
}

extension BlobCodec where Value: Codable {
  /// Uses fresh default JSON encoders and decoders for each operation.
  public static var json: Self {
    Self(
      encode: { try JSONEncoder().encode($0) },
      decode: { try JSONDecoder().decode(Value.self, from: $0) }
    )
  }
}