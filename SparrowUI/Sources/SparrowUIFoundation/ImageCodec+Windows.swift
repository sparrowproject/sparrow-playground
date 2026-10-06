#if os(Windows)
import Foundation
import UWP
@preconcurrency import Win2D
import WindowsFoundation

struct LosslessImageCodec: ImageCodec {
  func encode(_ image: ImageRef) async -> Data? {
    switch image {
    case .bitmap(let bitmap):
      return await encodeBitmap(bitmap)
    case .svg(let svg):
      return try? Data(svg.getXml().utf8)
    }
  }

  func decode(_ data: Data) async -> ImageRef? {
    if data.starts(with: Self.pngSignature) {
      return await decodeBitmap(data)
    }

    guard let xml = String(data: data, encoding: .utf8),
      let svg = try? CanvasSvgDocument.loadFromXml(CanvasDevice.getSharedDevice(), xml)
    else {
      return nil
    }

    return .svg(svg)
  }

  private func encodeBitmap(_ bitmap: CanvasBitmap) async -> Data? {
    do {
      let stream = InMemoryRandomAccessStream()
      try await bitmap.saveAsync(stream, .png).value

      let size = stream.size
      guard size <= UInt64(UInt32.max) else { return nil }

      try stream.seek(0)
      let buffer = Self.makeBuffer(capacity: UInt32(size))
      guard let result = try await stream.readAsync(buffer, UInt32(size), .none).value else {
        return nil
      }
      return Data(result.data)
    } catch {
      return nil
    }
  }

  private func decodeBitmap(_ data: Data) async -> ImageRef? {
    do {
      let stream = InMemoryRandomAccessStream()
      _ = try await stream.writeAsync(try Self.makeBuffer(data: data)).value
      try stream.seek(0)

      let bitmap = try await CanvasBitmap.loadAsync(CanvasDevice.getSharedDevice(), stream).value
      guard let bitmap else { return nil }
      return .bitmap(bitmap)
    } catch {
      return nil
    }
  }

  private static let pngSignature = Data([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])

  private static func makeBuffer(data: Data) throws -> UWP.Buffer {
    let buffer = makeBuffer(capacity: UInt32(data.count))
    guard let destination = try buffer.buffer else {
      throw WindowsFoundation.Error(hr: E_FAIL)
    }

    data.withUnsafeBytes { source in
      if let sourceBaseAddress = source.baseAddress {
        destination.update(
          from: sourceBaseAddress.assumingMemoryBound(to: UInt8.self),
          count: data.count
        )
      }
    }
    buffer.length = UInt32(data.count)
    return buffer
  }

  private static func makeBuffer(capacity: UInt32) -> UWP.Buffer {
    Buffer(capacity)
  }
}

#endif
