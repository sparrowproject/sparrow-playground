import Foundation

#if os(macOS)
import AppKit
#endif

@MainActor
public protocol ImageProvider: Sendable {
  func getImage() -> Future<ImageRef>
}

public typealias AnyImageProvider = any ImageProvider

/// Can be layered on top of another `ImageProvider` to provide a cached value.
public final class CachingImageProvider: ImageProvider {
  public init(source: ImageProvider) {
    self.source = source
  }

  public func getImage() -> Future<ImageRef> {
    switch state {
    case .loaded(let value):
      return .value(value)

    case .loading(let task):
      return .deferred(task)

    case .empty:
      switch source.getImage() {
      case .value(let value):
        return .value(value)
      case .deferred(let innerTask):
        let task = Task<ImageRef?, Never> {
          let value = await innerTask.value
          state = .loaded(value)
          return value
        }
        state = .loading(task)
        return .deferred(task)
      }
    }
  }

  private enum State {
    case empty
    case loading(Task<ImageRef?, Never>)
    case loaded(ImageRef?)
  }

  private let source: ImageProvider
  private var state = State.empty
}

/// Decodes given image data on demand.
public final class DecodingImageProvider: ImageProvider {
  public init(data: Data, codec: ImageCodec) {
    self.data = data
    self.codec = codec
  }

  public func getImage() -> Future<ImageRef> {
    .deferred(.init {
      await codec.decode(data)
    })
  }

  private let data: Data
  private let codec: ImageCodec
}