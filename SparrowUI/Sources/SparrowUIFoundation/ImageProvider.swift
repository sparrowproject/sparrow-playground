import Foundation

@MainActor
public protocol ImageProvider: Sendable {
  func getImage() async -> ImageRef?
}

public typealias AnyImageProvider = any ImageProvider

/// Can be layered on top of another `ImageProvider` to provide a cached value.
public final class CachingImageProvider: ImageProvider {
  public init(source: ImageProvider) {
    self.source = source
  }

  public func getImage() async -> ImageRef? {
    switch state {
    case .loaded(let value):
      return value

    case .loading(let task):
      return await task.value

    case .empty:
      let task = Task {
        await source.getImage()
      }

      state = .loading(task)

      let value = await task.value
      state = .loaded(value)
      return value
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

  public func getImage() async -> ImageRef? {
    await codec.decode(data)
  }

  private let data: Data
  private let codec: ImageCodec
}