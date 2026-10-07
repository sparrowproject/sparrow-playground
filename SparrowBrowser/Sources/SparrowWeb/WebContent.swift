import Foundation

#if os(macOS)
import WebKit
#elseif os(Windows)
import WinUI
#endif

@MainActor
public protocol WebContent: AnyObject {
  var model: WebContentModel { get }
  var action: ((WebContentAction) -> Void)? { get set }

  #if os(macOS)
  var webView: WKWebView { get }
  #elseif os(Windows)
  var webView: WebView2 { get }
  #endif

  var backForwardList: any WebContentBackForwardList { get }

  func load(url: URL)
  func goBack()
  func goForward()
  func goTo(_: any WebContentBackForwardListItem)
  func reload()
  func stop()
}
