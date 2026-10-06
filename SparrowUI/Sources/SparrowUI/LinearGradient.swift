import Foundation
import SparrowUICore
import SparrowUIFoundation

public struct LinearGradient: View {
  public init(
    stops: @autoclosure @MainActor @escaping () -> [Gradient.Stop],
    startPoint: @autoclosure @MainActor @escaping () -> UnitPoint,
    endPoint: @autoclosure @MainActor @escaping () -> UnitPoint,
  ) {
    self.stops = stops
    self.startPoint = startPoint
    self.endPoint = endPoint
  }

  public typealias Body = Never

  private let stops: @MainActor () -> [Gradient.Stop]
  private let startPoint: @MainActor () -> UnitPoint
  private let endPoint: @MainActor () -> UnitPoint
}

extension LinearGradient: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let view = CoreLinearGradientView(context: context)
    let colorSchemeGetter = view.effectiveColorSchemeGetter
    view.stops = {
      stops().map {
        CoreGradientStop(color: $0.color.resolved(with: colorSchemeGetter()), location: $0.location)
      }
    }
    view.startPoint = startPoint
    view.endPoint = endPoint
    return view
  }
}