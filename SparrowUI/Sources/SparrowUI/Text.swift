import Foundation
import SparrowUICore
import SparrowUIFoundation

public struct Text: View {
  public init(_ string: @autoclosure @MainActor @escaping () -> String) {
    self.string = string
    self.config = .init()
  }

  public typealias Body = Never

  private struct Config {
    var font: (@MainActor () -> Font) = { .default }
    var foregroundColor: (@MainActor () -> Color) = { .primaryText }
  }

  private init(
    string: @MainActor @escaping () -> String,
    config: Config,
  ) {
    self.string = string
    self.config = config
  }

  private let string: @MainActor () -> String
  private let config: Config
}

extension Text: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let text = CoreTextView(context: context)
    text.string = string
    text.font = config.font
    let colorSchemeGetter = text.effectiveColorSchemeGetter
    text.foregroundColor = { config.foregroundColor().resolved(with: colorSchemeGetter()) }
    return text
  }
}

extension Text {
  public func font(_ font: @autoclosure @MainActor @escaping () -> Font) -> Text {
    .init(
      string: string,
      config: with(config) { $0.font = font },
    )
  }

  public func foregroundColor(_ foregroundColor: @autoclosure @MainActor @escaping () -> Color) -> Text {
    .init(
      string: string,
      config: with(config) { $0.foregroundColor = foregroundColor }
    )
  }
}
