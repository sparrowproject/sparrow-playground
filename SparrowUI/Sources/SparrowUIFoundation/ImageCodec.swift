import Foundation

@MainActor
public protocol ImageCodec {
  func encode(_: ImageRef) async -> Data?
  func decode(_: Data) async -> ImageRef?
}

public enum ImageCodecs {
  public static var lossless: ImageCodec {
    LosslessImageCodec()
  }
}