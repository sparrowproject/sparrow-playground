import Foundation
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WindowsFoundation
import WinUI
#endif

public final class CoreEmbeddedView: CoreView {
  #if os(macOS)
  public typealias PlatformView = NSView
  #elseif os(Windows)
  public typealias PlatformView = UIElement
  #endif

  public init(
    context: CoreViewContext,
    makePlatformView: @MainActor @escaping (CoreView) -> PlatformView,
    tearDownPlatformView: @MainActor @escaping (PlatformView) -> Void,
  ) {
    self.embeddedViewToken = context.registerEmbeddedView()
    self.makePlatformView = makePlatformView
    self.tearDownPlatformView = tearDownPlatformView
    super.init(context: context)

    setUpObservers()
  }

  @MainActor
  deinit {
    tearDownPlatformView(platformView)
    context.unregisterEmbeddedView(token: embeddedViewToken)
  }

  override func setSuperview(_ superview: CoreView?) {
    super.setSuperview(superview)

    if superview != nil {
      context.attachEmbeddedView(platformView, token: embeddedViewToken)
    } else {
      context.detachEmbeddedView(token: embeddedViewToken)
    }
  }

  override func bindState() {
    super.bindState()

    bind({ [state] in state.globalPosition ?? .zero }, to: \CoreEmbeddedView.frameOrigin)
    bind({ [state] in state.effectiveSize }, to: \CoreEmbeddedView.frameSize)
  }

  private var frameOrigin: CGPoint = .zero {
    didSet {
      guard frameOrigin != oldValue else { return }

      #if os(macOS)
      if let animation {
        let layer = platformView.layer!
        let oldPosition = layer.position

        platformView.setFrameOrigin(frameOrigin)

        let newPosition = layer.position

        layer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = oldPosition
          $0.toValue = newPosition
          $0.keyPath = "position"
        }, forKey: "position")
      } else {
        platformView.setFrameOrigin(frameOrigin)
      }
      #elseif os(Windows)
      try! Canvas.setLeft(platformView, frameOrigin.x)
      try! Canvas.setTop(platformView, frameOrigin.y)

      if let animation {
        // Run a reverse translation animation.

        platformView.translation = .init(
          x: Float(oldValue.x - frameOrigin.x),
          y: Float(oldValue.y - frameOrigin.y),
          z: 0,
        )
        let newValue = Vector3(x: 0, y: 0, z: 0)

        try! platformView.startAnimation(
          with(animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor)) {
            $0.target = "Translation"
          }
        )
      }
      #endif
    }
  }

  private var frameSize: CGSize = .zero {
    didSet {
      guard frameSize != oldValue else { return }

      #if os(macOS)
      if let animation {
        let frameSize = self.frameSize
        let view = self.platformView
        context.sampleAnimation(
          animation.toBasicAnimation(),
          step: { fraction in
            let targetSize = CGSize(
              width: oldValue.width + fraction * (frameSize.width - oldValue.width),
              height: oldValue.height + fraction * (frameSize.height - oldValue.height),
            )
            view.setFrameSize(targetSize)
            view.layoutSubtreeIfNeeded()
          },
          completion: {
            view.setFrameSize(frameSize)
            view.layoutSubtreeIfNeeded()
          },
        )
      } else {
        platformView.setFrameSize(frameSize)
      }
      #elseif os(Windows)
      guard let frameworkElement = platformView as? FrameworkElement else { return }
      frameworkElement.width = frameSize.width
      frameworkElement.height = frameSize.height
      #endif
    }
  }

  private let embeddedViewToken: CoreViewContext.EmbeddedViewToken

  private(set) lazy var platformView: PlatformView = {
    let view = makePlatformView(self)
    #if os(macOS)
    view.wantsLayer = true
    #endif
    return view
  }()
  private let makePlatformView: (CoreView) -> PlatformView
  private let tearDownPlatformView: (PlatformView) -> Void

  private func setUpObservers() {
    onChange(
      of: { [state] in state.effectiveVisible },
      perform: { [weak self] in
        self?.updateVisibility(visible: $0)
      },
      cancellable: false,
    )
  }

  private func updateVisibility(visible: Bool) {
    #if os(macOS)
    platformView.isHidden = !visible
    #elseif os(Windows)
    platformView.visibility = visible ? .visible : .collapsed
    #endif
  }
}
