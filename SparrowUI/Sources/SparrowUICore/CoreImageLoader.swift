import Foundation
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import Win2D
#endif

@MainActor
public final class CoreImageLoader {
  public typealias CustomResolver = (_ id: String) -> AnyImageProvider?

  init(context: CoreViewContext) {
    self.context = context
  }

  func loadImage(source: ImageSource) -> Future<ImageRef> {
    if case .custom(let kind, let id) = source {
      return loadCustomImage(kind: kind, id: id)
    }

    #if os(macOS)

    if case .symbol(let source) = source {
      let image = NSImage(systemSymbolName: source.systemName, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: source.size, weight: .from(source.weight)))
      return .value(image)
    }
    if let fileURL = source.fileURL {
      return .deferred(.init {
        let data: Data? = await withCheckedContinuation { continuation in
          DispatchQueue(label: "image-loader").async {
            continuation.resume(returning: try? Data(contentsOf: fileURL))
          }
        }
        guard let data else { return nil }
        return await ImageCodecs.lossless.decode(data)
      })
    }
    return .value(nil)

    #elseif os(Windows)

    if case .symbol = source {
      print(">>> CoreImageLoader: ignoring symbol source!")
      return .value(nil)
    }
    
    // TODO: Add support for image formats other than SVG!
    return .deferred(.init {
      guard
        let url = source.fileURL,
        url.pathExtension.lowercased() == "svg",
        let xml = await loadFileAsString(url)
      else {
        print(">>> failed to load url: \(source.fileURL)")
        return nil
      }

      // TODO: Consider using loadAsync instead. However, the last time we tried that it crashed
      // within Win2D on a background thread.
      guard let svg = try? CanvasSvgDocument.loadFromXml(CanvasDevice.getSharedDevice(), xml) else {
        print(">>> failed to load svg at url: \(url)")
        return nil
      }
      return .svg(svg)
    })

    #endif
  }

  private let context: CoreViewContext

  private func loadCustomImage(kind: String, id: String) -> Future<ImageRef> {
    guard let resolver = context.imageSourceResolvers[kind] else {
      print(">>> unknown custom resolver, kind: \(kind)!")
      return .value(nil)
    }
    guard let provider = resolver(id) else {
      print(">>> provider is nil!")
      return .value(nil)
    }
    return provider.getImage()
  }
}

#if os(Windows)
private func loadFileAsString(_ url: URL) async -> String? {
  await withCheckedContinuation { continuation in
    DispatchQueue(label: "file-loader").async {
      continuation.resume(returning: try? String(contentsOf: url, encoding: .utf8))
    }
  }
}
#endif
