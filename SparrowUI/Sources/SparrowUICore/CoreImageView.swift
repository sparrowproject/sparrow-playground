import Foundation
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WindowsFoundation
import Win2D
import WinAppSDK
#endif

public final class CoreImageView: CoreView {
  public var source: @MainActor () -> ImageSource? {
    get { imageState.source }
    set { imageState.source = newValue }
  }

  public var resizable: @MainActor () -> Bool {
    get { imageState.resizable }
    set { imageState.resizable = newValue }
  }

  public var tintColor: @MainActor () -> CoreColor? {
    get { imageState.tintColor }
    set { imageState.tintColor = newValue }
  }

  public var loadingStatus: Binding<ImageLoadingStatus>? {
    didSet {
      loadingStatus?.set(_loadingStatus)
    }
  }

  final class ImageState: State {
    var source: @MainActor () -> ImageSource? = { nil }
    var resizable: @MainActor () -> Bool = { false }
    var tintColor: @MainActor () -> CoreColor? = { nil }
  }

  override func makeState() -> State {
    ImageState()
  }

  override func bindState() {
    super.bindState()

    bind({ [state = imageState] in state.source() }, to: \CoreImageView._source)
    bind({ [state = imageState] in state.resizable() }, to: \CoreImageView._resizable)
    bind({ [state = imageState] in state.tintColor() }, to: \CoreImageView._tintColor)

    #if os(Windows)
    bind({ [state] in state.effectiveSize }, to: \CoreImageView._renderSize)
    bind({ [context] in context.backingScaleFactor }, to: \CoreImageView._backingScaleFactor)
    #endif
  }

  #if os(macOS)
  override func makeLayer() -> CALayer {
    CoreImageLayer()
  }
  #endif

  private var _source: ImageSource? {
    didSet {
      guard _source != oldValue else { return }

      _loadingStatus = _source != nil ? .loading : .idle

      #if os(macOS)
      // Handle overlapped invocations.
      loadingTask?.cancel()
      loadingTask = Task<Void, Never> {
        let image: NSImage? =
          if let _source {
            await CoreImageLoader(context: context).loadImage(source: _source)
          } else {
            nil
          }
        guard !Task.isCancelled else { return }
        _loadingStatus = image != nil ? .loaded : .failed
        imageState.intrinsicSize = image?.size
        (layer as! CoreImageLayer).image = image
        loadingTask = nil
      }
      #endif

      #if os(Windows)
      cachedImage = nil
      scheduleRenderImage()
      #endif
    }
  }

  private var _resizable: Bool = false {
    didSet {
      guard _resizable != oldValue else { return }

      #if os(macOS)
      (layer as! CoreImageLayer).resizable = _resizable
      #elseif os(Windows)
      scheduleRenderImage()
      #endif
    }
  }

  private var _tintColor: CoreColor? {
    didSet {
      guard _tintColor != oldValue else { return }

      #if os(macOS)
      (layer as! CoreImageLayer).tintColor = _tintColor
      #elseif os(Windows)
      scheduleRenderImage()
      #endif
    }
  }

  private var _loadingStatus: ImageLoadingStatus = .idle {
    didSet {
      if let loadingStatus {
        loadingStatus.set(_loadingStatus)
      }
    }
  }

  private var imageState: ImageState {
    state as! ImageState
  }

  #if os(macOS)
  private var loadingTask: Task<Void, Never>?
  #endif

  #if os(Windows)
  private var renderImagePending = false
  private var surface: CompositionDrawingSurface?
  private var surfaceRasterTask: Task<Void, Never>?

  private var cachedImage: ImageRef? {
    didSet {
      guard cachedImage != oldValue else { return }
      imageState.intrinsicSize = cachedImage?.size
    }
  }

  private var _renderSize: CGSize = .zero {
    didSet {
      guard _renderSize != oldValue else { return }
      scheduleRenderImage()
    }
  }

  private var _backingScaleFactor: CGFloat = 1.0 {
    didSet {
      guard _backingScaleFactor != oldValue else { return }
      scheduleRenderImage()
    }
  }

  private func scheduleRenderImage() {
    guard !renderImagePending else { return }
    renderImagePending = true
    context.scheduler.scheduleDeferredUpdate { [weak self] in
      guard let self else { return }
      renderImagePending = false
      renderImage()
    }
  }

  private func renderImage() {
    guard _renderSize.width > 0, _renderSize.height > 0 else {
      resetVisual()
      return
    }

    surfaceRasterTask?.cancel()
    surfaceRasterTask = Task<Void, Never>.immediate {
      let image = await getImage()
      guard !Task.isCancelled else { return }
      defer {
        surfaceRasterTask = nil
      }
      guard let image else {
        print(">>> getImage failed, _source: \(_source)")
        resetVisual()
        _loadingStatus = .failed
        return
      }
      drawImage(image)
      _loadingStatus = .loaded
    }
  }

  private func getImage() async -> ImageRef? {
    guard let _source else { return nil }

    if cachedImage == nil {
      cachedImage = await CoreImageLoader(context: context).loadImage(source: _source)
      _loadingStatus = cachedImage != nil ? .loaded : .failed
    }
    return cachedImage
  }

  private func drawImage(_ image: ImageRef) {
    switch image {
    case .bitmap(let bitmap):
      drawBitmap(bitmap)
    case .svg(let svg):
      drawSvg(svg)
    }
  }

  private func drawBitmap(_ bitmap: CanvasBitmap) {
    let graphicsDevice = try! CanvasComposition.createCompositionGraphicsDevice(
      context.compositor,
      CanvasDevice.getSharedDevice(),
    )!

    let scale = Float(_backingScaleFactor)
    let renderSize = WindowsFoundation.Size(
      width: Float(_renderSize.width),
      height: Float(_renderSize.height),
    )
    let sizeInPixels = WindowsFoundation.Size(
      width: ceil(renderSize.width * scale),
      height: ceil(renderSize.height * scale),
    )

    let surface = try! graphicsDevice.createDrawingSurface(
      sizeInPixels,
      .b8g8r8a8uIntNormalized,
      .premultiplied,
    )

    let drawingSession = try! CanvasComposition.createDrawingSession(
      surface,
      .init(x: 0, y: 0, width: sizeInPixels.width, height: sizeInPixels.height),
      96 * scale,
    )!
    try! drawingSession.clear(CoreColor.clear.value)

    if _resizable {
      // TODO: Add option to preserve aspect ratio.
      try! drawingSession.drawImage(
        bitmap,
        .init(x: 0, y: 0, width: renderSize.width, height: renderSize.height),
      )
    } else {
      let imageSize = bitmap.size
      let destinationRect = WindowsFoundation.Rect(
        x: (renderSize.width - imageSize.width) / 2,
        y: (renderSize.height - imageSize.height) / 2,
        width: imageSize.width,
        height: imageSize.height,
      )
      try! drawingSession.drawImage(bitmap, destinationRect)
    }

    try! drawingSession.close()

    let brush = try! context.compositor.createSurfaceBrush(surface)!
    visual.brush = brush
  }

  private func drawSvg(_ svg: CanvasSvgDocument) {
    if let tintColor = _tintColor {
      try? svg.root.setColorAttribute("color", tintColor.value)
    }

    let graphicsDevice = try! CanvasComposition.createCompositionGraphicsDevice(
      context.compositor,
      CanvasDevice.getSharedDevice(),
    )!

    let scale = Float(_backingScaleFactor)
    let renderSize = WindowsFoundation.Size(
      width: Float(_renderSize.width),
      height: Float(_renderSize.height),
    )
    let sizeInPixels = WindowsFoundation.Size(
      width: ceil(renderSize.width * scale),
      height: ceil(renderSize.height * scale),
    )

    let surface = try! graphicsDevice.createDrawingSurface(
      sizeInPixels,
      .b8g8r8a8uIntNormalized,
      .premultiplied,
    )

    let drawingSession = try! CanvasComposition.createDrawingSession(
      surface,
      .init(x: 0, y: 0, width: sizeInPixels.width, height: sizeInPixels.height),
      96 * scale,
    )!
    try! drawingSession.clear(CoreColor.clear.value)

    if _resizable {
      // TODO: Add option to preserve aspect ratio.
      try! drawingSession.drawSvg(svg, renderSize)
    } else {
      let imageSize = svg.intrinsicSize ?? renderSize
      let offset = WindowsFoundation.Vector2(
        x: (renderSize.width - imageSize.width) / 2,
        y: (renderSize.height - imageSize.height) / 2,
      )
      try! drawingSession.drawSvg(svg, imageSize, offset)
    }

    try! drawingSession.close()

    let brush = try! context.compositor.createSurfaceBrush(surface)!
    visual.brush = brush
  }

  private func resetVisual() {
    visual.brush = try! context.compositor.createColorBrush(Colors.transparent)
  }
  #endif
}

#if os(macOS)
private final class CoreImageLayer: CALayer {
  var image: NSImage? {
    didSet {
      guard image !== oldValue else { return }

      CATransaction.begin()
      CATransaction.setDisableActions(true)

      imageLayer.contents = image

      CATransaction.commit()
    }
  }

  var resizable: Bool = false {
    didSet {
      guard resizable != oldValue else { return }
      imageLayer.contentsGravity = resizable ? .resizeAspect : .center
    }
  }

  var tintColor: CoreColor? {
    didSet {
      guard tintColor != oldValue else { return }
      if let tintColor {
        configureImageLayerAsMask()
        backgroundColor = tintColor.value
      } else {
        configureImageLayerAsChild()
        backgroundColor = .clear
      }
    }
  }

  override func layoutSublayers() {
    super.layoutSublayers()

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    imageLayer.frame = bounds

    if tintColor == nil {
      configureImageLayerAsChild()
    }

    CATransaction.commit()
  }

  // Load the image into this layer, and use it as a mask when applying a tint color.
  // Otherwise, it is just a child layer.
  private let imageLayer = CALayer()

  private func configureImageLayerAsMask() {
    if mask !== imageLayer {
      imageLayer.removeFromSuperlayer()
      mask = imageLayer
    }
  }

  private func configureImageLayerAsChild() {
    mask = nil
    addSublayer(imageLayer)
  }
}

#endif
