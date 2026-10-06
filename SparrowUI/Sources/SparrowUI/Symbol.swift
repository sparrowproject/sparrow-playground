import Foundation
import SparrowUICore
import SparrowUIFoundation

public struct Symbol: View {
  public init(source: @autoclosure @MainActor @escaping () -> SymbolSource?) {
    self._source = source
  }

  init(
    source: @MainActor @escaping () -> SymbolSource?,
    tintColor: (@MainActor () -> Color?)?,
  ) {
    _source = source
    _tintColor = tintColor
  }

  public var body: some View {
    #if os(macOS)
    Image(source: _source().flatMap({ .symbol($0) }))
      .tintColor(effectiveTintColor)
    #elseif os(Windows)
    Text(_source().flatMap({ $0.glyph }) ?? "")
      .font(effectiveFont)
      .foregroundColor(effectiveTintColor)
    #endif
  }

  private let _source: @MainActor () -> SymbolSource?
  private var _tintColor: (@MainActor () -> Color?)?

  private var effectiveTintColor: Color {
    _tintColor?() ?? .primaryText
  }

  #if os(Windows)
  private var effectiveFont: Font {
    .system(size: _source()?.size ?? 14, weight: _source()?.weight ?? .regular, design: .symbol)
  }
  #endif
}

extension Symbol {
  public func tintColor(_ tintColor: @autoclosure @MainActor @escaping () -> Color) -> Symbol {
    .init(
      source: _source,
      tintColor: tintColor,
    )
  }
}