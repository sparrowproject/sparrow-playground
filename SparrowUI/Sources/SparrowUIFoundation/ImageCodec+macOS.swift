#if os(macOS)
import AppKit
import ObjectiveC
import WebKit

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
    if let document = try? XMLDocument(data: data, options: .nodeLoadExternalEntitiesNever),
      let root = document.rootElement(), root.localName == "svg",
      root.uri == "http://www.w3.org/2000/svg" || root.uri == nil
    {
      let renderer = SVGCanvasRenderer()
      guard let png = await renderer.render(data), let image = NSImage(data: png) else {
        return nil
      }
      objc_setAssociatedObject(image, &svgDataKey, data, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return image
    }
    return await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        continuation.resume(returning: NSImage(data: data))
      }
    }
  }
}

@MainActor
private final class SVGCanvasRenderer: NSObject, WKNavigationDelegate {
  private let webView: WKWebView
  private var continuation: CheckedContinuation<Data?, Never>?
  private var svg = Data()
  private var timeout: Task<Void, Never>?

  override init() {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
    super.init()
    webView.navigationDelegate = self
  }

  func render(_ data: Data) async -> Data? {
    svg = data
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      timeout = Task { [weak self] in
        try? await Task.sleep(for: .seconds(10))
        guard !Task.isCancelled else { return }
        self?.finish(nil)
      }
      webView.loadHTMLString("<html><body></body></html>", baseURL: nil)
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    Task {
      do {
        let result = try await webView.callAsyncJavaScript(
          """
          const bytes = Uint8Array.from(atob(source), c => c.charCodeAt(0));
          const url = URL.createObjectURL(new Blob([bytes], {type: 'image/svg+xml'}));
          try {
            const image = new Image();
            image.src = url;
            await image.decode();
            const canvas = document.createElement('canvas');
            canvas.width = image.naturalWidth;
            canvas.height = image.naturalHeight;
            if (!canvas.width || !canvas.height) throw new Error('Invalid SVG dimensions');
            canvas.getContext('2d').drawImage(image, 0, 0);
            return canvas.toDataURL('image/png').split(',')[1];
          } finally {
            URL.revokeObjectURL(url);
          }
          """,
          arguments: ["source": svg.base64EncodedString()], in: nil, contentWorld: .page
        )
        finish((result as? String).flatMap { Data(base64Encoded: $0) })
      } catch {
        finish(nil)
      }
    }
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
    finish(nil)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
    finish(nil)
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    finish(nil)
  }

  private func finish(_ data: Data?) {
    guard let continuation else { return }
    self.continuation = nil
    timeout?.cancel()
    webView.stopLoading()
    continuation.resume(returning: data)
  }
}
#endif
