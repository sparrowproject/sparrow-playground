import Foundation
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WinAppSDK
import WindowsFoundation
#endif

public final class CoreShapeView: CoreView {
  public var path: (@MainActor (CGSize) -> Path?)? {
    get { shapeState.path }
    set { shapeState.path = newValue }
  }

  public var fillColor: (@MainActor () -> CoreColor?)? {
    get { shapeState.fillColor }
    set { shapeState.fillColor = newValue }
  }

  public var strokeColor: (@MainActor () -> CoreColor?)? {
    get { shapeState.strokeColor }
    set { shapeState.strokeColor = newValue }
  }

  final class ShapeState: State {
    var path: (@MainActor (CGSize) -> Path?)?
    var fillColor: (@MainActor () -> CoreColor?)?
    var strokeColor: (@MainActor () -> CoreColor?)?

    var effectivePath: Path? {
      if let path {
        path(effectiveSize)
      } else {
        nil
      }
    }

    var effectiveFillColor: CoreColor? {
      if let fillColor {
        fillColor()
      } else {
        nil
      }
    }

    var effectiveStrokeColor: CoreColor? {
      if let strokeColor {
        strokeColor()
      } else {
        nil
      }
    }
  }

  #if os(macOS)
  override func makeLayer() -> CALayer {
    CAShapeLayer()
  }
  #elseif os(Windows)
  override func configureVisual(_ visual: SpriteVisual) {
    visual.borderMode = .soft
  }

  override func contentBrush() -> CompositionBrush? {
    visualSurfaceBrush
  }

  override func configureDropShadow(_ dropShadow: DropShadow) {
    super.configureDropShadow(dropShadow)
    dropShadow.mask = visualSurfaceBrush
  }
  #endif

  override func makeState() -> State {
    ShapeState()
  }

  override func bindState() {
    super.bindState()

    bind({ [state = shapeState] in state.effectivePath }, to: \CoreShapeView._path)
    bind({ [state = shapeState] in state.effectiveFillColor }, to: \CoreShapeView._fillColor)
    bind({ [state = shapeState] in state.effectiveStrokeColor }, to: \CoreShapeView._strokeColor)
  }

  var shapeState: ShapeState {
    state as! ShapeState
  }

  var _path: Path? {
    didSet {
      guard _path != oldValue else { return }

      #if os(macOS)
      let shapeLayer = layer as! CAShapeLayer
      let cgPath = _path?.cgPath
      if let animation {
        shapeLayer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = shapeLayer.presentation()?.path ?? oldValue?.cgPath
          $0.toValue = cgPath
          $0.keyPath = "path"
        }, forKey: "path")
      }
      shapeLayer.path = cgPath
      #elseif os(Windows)
      let newValue = _path.flatMap { CompositionPath($0.canvasGeometry) }
      if let animation, let newValue {
        try! geometry.startAnimation(
          "Path",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor)
        )
      } else {
        // The path previously specified via animation will override until stopped explicitly.
        try! geometry.stopAnimation("Path")
        geometry.path = newValue
      }
      #endif
    }
  }

  #if os(Windows)
  private lazy var shape: CompositionSpriteShape = try! context.compositor.createSpriteShape()!
  private lazy var geometry: CompositionPathGeometry = try! context.compositor.createPathGeometry()

  private lazy var shapeVisual: ShapeVisual = {
    let shapeVisual = try! context.compositor.createShapeVisual()!
    shapeVisual.shapes.append(shape)
    shapeVisual.borderMode = .soft
    shape.fillBrush = fillBrush
    shape.strokeBrush = strokeBrush
    shape.geometry = geometry
    return shapeVisual
  }()

  private lazy var visualSurface: CompositionVisualSurface = {
    let visualSurface = try! context.compositor.createVisualSurface()!
    visualSurface.sourceVisual = shapeVisual
    return visualSurface
  }()

  private lazy var visualSurfaceBrush: CompositionSurfaceBrush = {
    let brush = try! context.compositor.createSurfaceBrush(visualSurface)!
    brush.stretch = .fill
    brush.bitmapInterpolationMode = .magLinearMinLinearMipLinear
    return brush
  }()

  private lazy var fillBrush: CompositionColorBrush = try! context.compositor.createColorBrush()
  private lazy var strokeBrush: CompositionColorBrush = try! context.compositor.createColorBrush()

  override func sizeChanged(value shapeSize: CGSize) {
    super.sizeChanged(value: shapeSize)

    let newValue = Vector2(x: Float(shapeSize.width), y: Float(shapeSize.height))
    if let animation {
      let compositionAnimation = animation.toCompositionAnimation(
        withTargetValue: newValue,
        compositor: context.compositor,
      )
      try! shapeVisual.startAnimation("Size", compositionAnimation)
      try! visualSurface.startAnimation("SourceSize", compositionAnimation)
    } else {
      shapeVisual.size = newValue
      visualSurface.sourceSize = newValue
    }
  }
  #endif

  private var _fillColor: CoreColor? {
    didSet {
      guard _fillColor != oldValue else { return }

      #if os(macOS)
      let shapeLayer = layer as! CAShapeLayer

      if let animation {
        layer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = shapeLayer.presentation()?.fillColor ?? oldValue?.value
          $0.toValue = _fillColor?.value
          $0.keyPath = "fillColor"
        }, forKey: "fillColor")
      }
      shapeLayer.fillColor = _fillColor?.value
      #elseif os(Windows)
      let newValue = (_fillColor ?? .clear).value
      if let animation {
        try! fillBrush.startAnimation(
          "Color",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
      } else {
        fillBrush.color = newValue
      }
      #endif
    }
  }

  private var _strokeColor: CoreColor? {
    didSet {
      guard _strokeColor != oldValue else { return }

      #if os(macOS)
      let shapeLayer = layer as! CAShapeLayer

      if let animation {
        layer.add(with(animation.toBasicAnimation()) {
          $0.fromValue = shapeLayer.presentation()?.strokeColor ?? oldValue?.value
          $0.toValue = _strokeColor?.value
          $0.keyPath = "strokeColor"
        }, forKey: "strokeColor")
      }
      shapeLayer.strokeColor = _strokeColor?.value
      #elseif os(Windows)
      let newValue = (_strokeColor ?? .clear).value
      if let animation {
        try! strokeBrush.startAnimation(
          "Color",
          animation.toCompositionAnimation(withTargetValue: newValue, compositor: context.compositor),
        )
      } else {
        strokeBrush.color = newValue
      }
      #endif
    }
  }
}
