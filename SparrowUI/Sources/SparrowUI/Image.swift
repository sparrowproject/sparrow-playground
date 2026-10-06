import Foundation
import SparrowUICore
import SparrowUIFoundation

public struct Image: View {
  public init(source: @autoclosure @MainActor @escaping () -> ImageSource?) {
    self._source = source
  }

  public var body: some View {
    #if os(macOS)
    _CoreImage(
      source: _source,
      resizable: _resizable,
      tintColor: _tintColor,
      loadingStatus: _loadingStatus,
    )
    #elseif os(Windows)
    // Use an overlay here so that the intrinsic sizing of the `CoreImageView` still applies.
    _CoreImage(
      source: _source,
      resizable: _resizable,
      tintColor: _tintColor,
      loadingStatus: _loadingStatus,
    )
    .opacity(symbolSource == nil ? 1 : 0)
    .overlay(
      Symbol(
        source: { symbolSource },
        tintColor: _tintColor,
      )
      .opacity(symbolSource != nil ? 1 : 0)
    )
    #endif
  }

  private init(
    source: @MainActor @escaping () -> ImageSource?,
    resizable: (@MainActor () -> Bool)?,
    tintColor: (@MainActor () -> Color?)?,
    loadingStatus: Binding<ImageLoadingStatus>?,
  ) {
    _source = source
    _resizable = resizable
    _tintColor = tintColor
    _loadingStatus = loadingStatus
  }

  private let _source: @MainActor () -> ImageSource?
  private var _resizable: (@MainActor () -> Bool)?
  private var _tintColor: (@MainActor () -> Color?)?
  private var _loadingStatus: Binding<ImageLoadingStatus>?

  #if os(Windows)
  private var symbolSource: SymbolSource? {
    switch _source() {
    case .symbol(let symbolSource):
      symbolSource
    default:
      nil
    }
  }
  #endif
}

struct _CoreImage: View {
  typealias Body = Never

  let source: @MainActor () -> ImageSource?
  let resizable: (@MainActor () -> Bool)?
  let tintColor: (@MainActor () -> Color?)?
  let loadingStatus: Binding<ImageLoadingStatus>?
}

extension _CoreImage: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let image = CoreImageView(context: context)
    image.source = source
    image.resizable = resizable ?? { false }
    let colorSchemeGetter = image.effectiveColorSchemeGetter
    image.tintColor = {
      tintColor.flatMap { $0()?.resolved(with: colorSchemeGetter()) }
    }
    image.loadingStatus = loadingStatus
    return image
  }
}

extension Image {
  public func resizable(_ resizable: @autoclosure @MainActor @escaping () -> Bool = true) -> Image {
    .init(
      source: _source,
      resizable: resizable,
      tintColor: _tintColor,
      loadingStatus: _loadingStatus,
    )
  }

  public func tintColor(_ tintColor: @autoclosure @MainActor @escaping () -> Color?) -> Image {
    .init(
      source: _source,
      resizable: _resizable,
      tintColor: tintColor,
      loadingStatus: _loadingStatus,
    )
  }

  public func readLoadingStatus(to value: Binding<ImageLoadingStatus>) -> Image {
    .init(
      source: _source,
      resizable: _resizable,
      tintColor: _tintColor,
      loadingStatus: value,
    )
  }
}