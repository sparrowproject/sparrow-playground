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

  func loadImage(source: ImageSource) async -> ImageRef? {
    if case .custom(let kind, let id) = source {
      return await loadCustomImage(kind: kind, id: id)
    }

    #if os(macOS)
    if case .symbol(let source) = source {
      return NSImage(systemSymbolName: source.systemName, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: source.size, weight: .from(source.weight)))
    }
    #elseif os(Windows)
    if case .symbol = source {
      print(">>> CoreImageLoader: ignoring symbol source!")
      return nil
    }
    #endif

    if let fileURL = source.fileURL {
      // TODO: Consider how to add a cache here.
      let data: Data? = await withCheckedContinuation { continuation in
        DispatchQueue(label: "image-loader").async {
          continuation.resume(returning: try? Data(contentsOf: fileURL))
        }
      }
      guard let data else { return nil }
      return await ImageCodecs.lossless.decode(data)
    }

    return nil
  }

  private let context: CoreViewContext

  private func loadCustomImage(kind: String, id: String) async -> ImageRef? {
    guard let resolver = context.imageSourceResolvers[kind] else {
      print(">>> unknown custom resolver, kind: \(kind)!")
      return nil
    }
    guard let provider = resolver(id) else {
      print(">>> provider is nil!")
      return nil
    }
    return await provider.getImage()
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
