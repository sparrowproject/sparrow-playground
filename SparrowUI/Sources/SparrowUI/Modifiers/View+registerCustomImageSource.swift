import SparrowUICore
import SparrowUIFoundation

extension View {
  public func registerCustomImageSource<Source: CustomImageSource>(_ source: Source) -> some View {
    modifier(_RegisterImageSourceModifier(source: source))
  }
}

@MainActor
public struct _RegisterImageSourceModifier<Source: CustomImageSource> {
  let source: Source
}

extension _RegisterImageSourceModifier: ViewModifier {
  public typealias Body = Never
}

extension _RegisterImageSourceModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    view.context.imageSourceResolvers[source.kind] = { source.resolve(id: $0) }
  }
}
