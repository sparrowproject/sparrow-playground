import Foundation

#if os(Windows)
import SparrowUIFoundation
internal import UWP
internal import WindowsFoundation
#endif

@MainActor
public protocol NetworkRequest: AnyObject {
  var model: NetworkRequestModel { get }

  func cancel()
}

final class DefaultNetworkRequest: NetworkRequest {
  init(url: URL) {
    model = .init(url: url)

    loadTask = .init {
      do {
        model.data = try await Self.fetchData(from: url)
      } catch {
        print(">>> network request failed: \(error)")
      }
      model.status = .done
      loadTask = nil
    }
  }

  let model: NetworkRequestModel
  var loadTask: Task<Void, Never>?

  func cancel() {
    loadTask?.cancel()
    loadTask = nil
  }

  #if os(macOS)
  private static func fetchData(from url: URL) async throws -> Data? {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
  }
  #elseif os(Windows)
  private static func fetchData(from url: URL) async throws -> Data? {
    let client = HttpClient()
    defer {
      try? client.close()
    }

    let uri = Uri(url.absoluteString)
    let buffer = try await client.getBufferAsync(uri).value
    let dataReader = try DataReader.fromBuffer(buffer)
    defer {
      try? dataReader?.close()
    }

    guard let dataReader, let buffer else {
      return nil
    }

    var bytes = [UInt8](repeating: 0, count: Int(buffer.length))
    try dataReader.readBytes(&bytes)
    return Data(bytes)
  }
  #endif
}
