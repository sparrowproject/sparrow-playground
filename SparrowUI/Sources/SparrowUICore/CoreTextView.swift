import Foundation
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WindowsFoundation
import Win2D
import WinAppSDK
#endif

open class CoreTextView: CoreView {
  final class TextState: State {
    var string: (@MainActor () -> String)?
    var font: (@MainActor () -> Font)?
    var foregroundColor: (@MainActor () -> CoreColor)?

    var effectiveString: String {
      if let string {
        string()
      } else {
        ""
      }
    }

    var effectiveFont: Font {
      if let font {
        font()
      } else {
        .default
      }
    }

    var effectiveForegroundColor: CoreColor {
      if let foregroundColor {
        foregroundColor()
      } else {
        .black
      }
    }

    func computeIntrinsicSize() -> CGSize? {
      // TODO: Figure out how to cache this LineBuilder instance.
      let lineBuilder = TextLineBuilder(
        text: effectiveString,
        font: effectiveFont,
      )
      return .init(width: lineBuilder.width, height: lineBuilder.height)
    }
  }

  public var string: (@MainActor () -> String)? {
    get { textState.string }
    set { textState.string = newValue }
  }

  public var font: (@MainActor () -> Font)? {
    get { textState.font }
    set { textState.font = newValue }
  }

  public var foregroundColor: (@MainActor () -> CoreColor)? {
    get { textState.foregroundColor }
    set { textState.foregroundColor = newValue }
  }

  var textState: TextState {
    state as! TextState
  }

  #if os(macOS)
  override func makeLayer() -> CALayer {
    CoreTextLayer()
  }
  #elseif os(Windows)
  override func contentBrush() -> CompositionBrush? {
    surfaceBrush
  }
  #endif

  override func makeState() -> State {
    TextState()
  }

  override func bindState() {
    super.bindState()

    bind({ [state = textState] in state.effectiveString }, to: \CoreTextView._string)
    bind({ [state = textState] in state.effectiveFont }, to: \CoreTextView._font)
    bind({ [state = textState] in state.effectiveForegroundColor }, to: \CoreTextView._foregroundColor)

    bind({ [state = textState] in state.computeIntrinsicSize() }, to: \CoreView.state.intrinsicSize)

    bind({ [context] in context.backingScaleFactor }, to: \CoreTextView._backingScaleFactor)
  }

  private var renderTextPending = false

  private var _string: String = "" {
    didSet {
      guard _string != oldValue else { return }

      #if os(macOS)
      let textLayer = layer as! CoreTextLayer
      textLayer.text = _string
      #elseif os(Windows)
      // print(">>> _string value changed, from: \(oldValue), to: \(_string)")
      cachedLineBuilder = nil
      #endif
      scheduleRenderText()
    }
  }

  private var _font: Font = .default {
    didSet {
      guard _font != oldValue else { return }

      #if os(macOS)
      let textLayer = layer as! CoreTextLayer
      textLayer.font = _font
      #elseif os(Windows)
      // print(">>> _font value changed")
      cachedLineBuilder = nil
      #endif
      scheduleRenderText()
    }
  }

  private var _foregroundColor: CoreColor = .black {
    didSet {
      guard _foregroundColor != oldValue else { return }

      #if os(macOS)
      let textLayer = layer as! CoreTextLayer
      textLayer.foregroundColor = _foregroundColor
      #elseif os(Windows)
      // print(">>> _foregroundColor value changed")
      #endif
      scheduleRenderText()
    }
  }

  private var _backingScaleFactor: CGFloat = 1.0 {
    didSet {
      guard _backingScaleFactor != oldValue else { return }
      #if os(macOS)
      let textLayer = layer as! CoreTextLayer
      textLayer.backingScaleFactor = _backingScaleFactor
      #elseif os(Windows)
      #endif
      scheduleRenderText()
    }
  }

  private func scheduleRenderText() {
    guard !renderTextPending else { return }
    renderTextPending = true
    context.scheduler.scheduleDeferredUpdate { [weak self] in
      guard let self else { return }
      renderTextPending = false
      renderText()
    }
  }

  #if os(macOS)
  private func renderText() {
    let textLayer = layer as! CoreTextLayer
    textLayer.renderText()
  }
  #endif

  #if os(Windows)
  private var cachedLineBuilder: TextLineBuilder?

  private lazy var surfaceBrush: CompositionSurfaceBrush = {
    let brush = try! context.compositor.createSurfaceBrush()!
    brush.stretch = CompositionStretch.none
    brush.horizontalAlignmentRatio = 0
    brush.verticalAlignmentRatio = 0
    return brush
  }()

  private func renderText() {
    let lineBuilder = cachedLineBuilder ?? {
      let lineBuilder = TextLineBuilder(
        text: _string,
        font: _font,
      )
      cachedLineBuilder = lineBuilder
      return lineBuilder
    }()

    guard lineBuilder.width > 0, lineBuilder.height > 0 else {
      try! visual.children.removeAll()
      return
    }

    let graphicsDevice = try! CanvasComposition.createCompositionGraphicsDevice(
      context.compositor,
      CanvasDevice.getSharedDevice(),
    )!

    let scale = Float(context.backingScaleFactor)

    let sizeInPixels = Size(
      width: ceil(Float(lineBuilder.width) * scale),
      height: ceil(Float(lineBuilder.height) * scale),
    )

    let surface = try! graphicsDevice.createDrawingSurface(
      sizeInPixels,
      .b8g8r8a8uIntNormalized,
      .premultiplied,
    )

    let dpi = 96 * scale

    let drawingSession = try! CanvasComposition.createDrawingSession(
      surface,
      .init(x: 0, y: 0, width: sizeInPixels.width, height: sizeInPixels.height),
      dpi,
    )!
    try! drawingSession.clear(CoreColor.clear.value)
    try! drawingSession.drawTextLayout(lineBuilder.layout, 0, 0, _foregroundColor.value)

    surfaceBrush.surface = surface
    surfaceBrush.scale = .init(x: 1 / scale, y: 1 / scale)

    // The below seems to no longer make any difference, which makes sense.

    // // Create a SpriteVisual sized to match the underlying surface. This way we allow
    // // the outer `visual` to have non-pixel aligned sizing, avoiding rendering artifacts.
    // // TODO: Still feels like this should be unnecessary. More investigation is warranted.
    // let textVisual = try! context.compositor.createSpriteVisual()!
    // textVisual.size = .init(
    //   x: sizeInPixels.width * scale,
    //   y: sizeInPixels.height * scale,
    // )
    // textVisual.brush = brush

    // try! visual.children.removeAll()
    // try! visual.children.insertAtTop(textVisual)
  }
  #endif
}

#if os(macOS)
private final class CoreTextLayer: CALayer {
  var text: String = ""
  var font: Font = .default
  var foregroundColor: CoreColor = .black
  var backingScaleFactor: CGFloat = 1

  override init() {
    super.init()
    isGeometryFlipped = true
    needsDisplayOnBoundsChange = true
  }

  // This needs to be implemented to avoid a crash.
  override init(layer: Any) {
    super.init(layer: layer)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  override func draw(in cgContext: CGContext) {
    super.draw(in: cgContext)

    let lineBuilder = TextLineBuilder(text: text, font: font)

    cgContext.saveGState()
    cgContext.textMatrix = .identity
    cgContext.textPosition = .init(x: 0, y: lineBuilder.descent)
    cgContext.setFillColor(foregroundColor.value)

    CTLineDraw(lineBuilder.line, cgContext)

    cgContext.restoreGState()
  }

  func renderText() {
    contentsScale = backingScaleFactor
    setNeedsDisplay()
    displayIfNeeded()
  }
}
#endif