#if os(Windows)
import UWP
import Win2D

public struct ImageFromStreamProvider: ImageProvider {
  public init(stream: AnyIRandomAccessStream) {
    self.stream = stream
    initialPos = stream.position
  }

  public func getImage() async -> ImageRef? {
    let device = try! CanvasDevice.getSharedDevice()

    guard let bitmap = try? await CanvasBitmap.loadAsync(device, stream).value else {
      return nil
    }

    return .bitmap(bitmap)
  }

  private let stream: AnyIRandomAccessStream
  private let initialPos: UInt64
}

#endif