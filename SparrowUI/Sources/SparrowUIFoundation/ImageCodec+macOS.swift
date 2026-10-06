#if os(macOS)
import AppKit
import ObjectiveC

private nonisolated(unsafe) var svgDataKey: UInt8 = 0

struct LosslessImageCodec: ImageCodec {
  func encode(_ image: ImageRef) async -> Data? {
    await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        if let data = objc_getAssociatedObject(image, &svgDataKey) as? Data {
          continuation.resume(returning: data)
          return
        }

        if
          let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:])
        {
          continuation.resume(returning: data)
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }

  func decode(_ data: Data) async -> ImageRef? {
    await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        guard let image = NSImage(data: data) else {
          continuation.resume(returning: nil)
          return
        }

        // AppKit can render SVGs, but does not expose their source for encoding.
        // Keep the XML so a lossless round trip does not rasterize the image.
        if image.representations.contains(where: { !($0 is NSBitmapImageRep) }),
          let document = try? XMLDocument(data: data, options: .nodeLoadExternalEntitiesNever),
          let root = document.rootElement(),
          root.localName == "svg",
          root.uri == "http://www.w3.org/2000/svg" || root.uri == nil
        {
          objc_setAssociatedObject(image, &svgDataKey, data, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        continuation.resume(returning: image)
      }
    }
  }
}

#endif
