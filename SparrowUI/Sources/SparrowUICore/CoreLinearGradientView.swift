import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WinAppSDK
#endif

public final class CoreLinearGradientView: CoreView {
  public var stops: @MainActor () -> [CoreGradientStop] {
    get { linearGradientState.stops }
    set { linearGradientState.stops = newValue }
  }

  public var startPoint: @MainActor () -> UnitPoint {
    get { linearGradientState.startPoint }
    set { linearGradientState.startPoint = newValue }
  }

  public var endPoint: @MainActor () -> UnitPoint {
    get { linearGradientState.endPoint }
    set { linearGradientState.endPoint = newValue }
  }

  final class LinearGradientState: State {
    var stops: @MainActor () -> [CoreGradientStop] = { [] }
    var startPoint: @MainActor () -> UnitPoint = { .zero }
    var endPoint: @MainActor () -> UnitPoint = { .zero }
  }

  #if os(macOS)
  override func makeLayer() -> CALayer {
    CAGradientLayer()
  }
  #elseif os(Windows)
  override func contentBrush() -> CompositionBrush? {
    gradientBrush
  }
  #endif

  override func makeState() -> State {
    LinearGradientState()
  }

  override func bindState() {
    super.bindState()

    bind({ [state = linearGradientState] in state.stops() }, to: \CoreLinearGradientView._stops)
    bind({ [state = linearGradientState] in state.startPoint() }, to: \CoreLinearGradientView._startPoint)
    bind({ [state = linearGradientState] in state.endPoint() }, to: \CoreLinearGradientView._endPoint)
  }

  var linearGradientState: LinearGradientState {
    state as! LinearGradientState
  }

  #if os(Windows)
  private lazy var gradientBrush = try! context.compositor.createLinearGradientBrush()!
  #endif

  private var _stops = [CoreGradientStop]() {
    didSet {
      guard _stops != oldValue else { return }

      #if os(macOS)
      let gradientLayer = layer as! CAGradientLayer
      gradientLayer.colors = _stops.map(\.color.value)
      gradientLayer.locations = _stops.map(\.location).map { NSNumber(value: $0) }
      #elseif os(Windows)
      gradientBrush.colorStops.replaceAll(_stops.map {
        try! context.compositor.createColorGradientStop(Float($0.location), $0.color.value)
      })
      #endif
    }
  }

  private var _startPoint: UnitPoint = .zero {
    didSet {
      guard _startPoint != oldValue else { return }

      #if os(macOS)
      let gradientLayer = layer as! CAGradientLayer
      gradientLayer.startPoint = .from(_startPoint)
      #elseif os(Windows)
      gradientBrush.startPoint = .from(_startPoint)
      #endif
    }
  }

  private var _endPoint: UnitPoint = .zero {
    didSet {
      guard _endPoint != oldValue else { return }

      #if os(macOS)
      let gradientLayer = layer as! CAGradientLayer
      gradientLayer.endPoint = .from(_endPoint)
      #elseif os(Windows)
      gradientBrush.endPoint = .from(_endPoint)
      #endif
    }
  }
}