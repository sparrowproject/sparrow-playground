import Foundation
import Observation
import OrderedCollections
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WinAppSDK
import WinUI
#endif

@MainActor
@Observable
public final class CoreViewContext {
  #if os(macOS)
  public typealias EmbeddedView = NSView
  #elseif os(Windows)
  public typealias EmbeddedView = UIElement
  #endif

  @MainActor
  public protocol Delegate: AnyObject {
    func didFlushUpdates()

    #if os(macOS)
    var containingNSView: NSView { get }
    func sampleAnimation(_: CABasicAnimation, step: @escaping (CGFloat) -> Void, completion: @escaping () -> Void)
    func addEmbeddedNSView(_: NSView)
    #elseif os(Windows)
    var containingUIElement: UIElement { get }
    func addEmbeddedUIElement(_: UIElement)
    func removeEmbeddedUIElement(_: UIElement)
    #endif

    func updateEmbeddedViews(_: [EmbeddedView])
  }

  public init(scheduler: CoreScheduler = .init()) {
    self.scheduler = scheduler

    scheduler.observeUpdates { [weak self] in
      self?.delegate?.didFlushUpdates()
    }
  }

  public convenience init(derivedFrom other: CoreViewContext) {
    self.init(scheduler: other.scheduler)
    imageSourceResolvers = other.imageSourceResolvers
  }

  public let scheduler: CoreScheduler
  public var colorScheme: ColorScheme = .light
  public var backingScaleFactor: CGFloat = 1.0
  public weak var focusedView: CoreView?

  @ObservationIgnored public weak var rootView: CoreView?
  @ObservationIgnored public weak var delegate: Delegate?

  @ObservationIgnored public var imageSourceResolvers = [String: CoreImageLoader.CustomResolver]()

  struct EmbeddedViewToken: Hashable {
    fileprivate let id: Int
  }

  #if os(Windows)
  let compositor: Compositor = try! CompositionTarget.getCompositorForCurrentThread()
  #endif

  func registerEmbeddedView() -> EmbeddedViewToken {
    let token = EmbeddedViewToken(id: nextEmbeddedViewTokenID)
    nextEmbeddedViewTokenID += 1
    embeddedViewTokens.append(token)
    return token
  }

  func attachEmbeddedView(_ view: EmbeddedView, token: EmbeddedViewToken) {
    attachedViews[token] = view
    updateEmbeddedViews()
  }

  func detachEmbeddedView(token: EmbeddedViewToken) {
    attachedViews.removeValue(forKey: token)
    updateEmbeddedViews()
  }

  func unregisterEmbeddedView(token: EmbeddedViewToken) {
    attachedViews.removeValue(forKey: token)
    embeddedViewTokens.remove(token)
    updateEmbeddedViews()
  }

  #if os(macOS)
  func sampleAnimation(_ animation: CABasicAnimation, step: @escaping (CGFloat) -> Void, completion: @escaping () -> Void) {
    delegate?.sampleAnimation(animation, step: step, completion: completion)
  }
  #endif

  @ObservationIgnored private var nextEmbeddedViewTokenID = 1
  /// Provides ordering for embedded views that are attached later on.
  @ObservationIgnored private var embeddedViewTokens = OrderedSet<EmbeddedViewToken>()
  @ObservationIgnored private var attachedViews = [EmbeddedViewToken: EmbeddedView]()

  private func updateEmbeddedViews() {
    guard let delegate else { return }

    var orderedChildren = [EmbeddedView]()
    for token in embeddedViewTokens {
      if let view = attachedViews[token] {
        orderedChildren.append(view)
      }
    }
    delegate.updateEmbeddedViews(orderedChildren)
  }
}

#if os(macOS)
extension CoreViewContext {
  public var containingNSView: NSView? {
    delegate?.containingNSView
  }

  public var containingNSWindow: NSWindow? {
    delegate?.containingNSView.window
  }
}
#endif

#if os(Windows)
extension CoreViewContext {
  public var containingUIElement: UIElement? {
    delegate?.containingUIElement
  }

  public var containingAppWindow: AppWindow? {
    delegate?.containingUIElement.appWindow
  }
}
#endif

@MainActor
@Observable
public final class ColorSchemeProvider {
  public var colorScheme = ColorScheme.light

  public static let shared = ColorSchemeProvider()
}
