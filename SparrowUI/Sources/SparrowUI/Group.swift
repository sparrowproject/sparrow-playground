import Foundation
import SparrowUICore

public struct Group<Content>: View where Content: View {
  public init(@ViewSequence _ content: @escaping () -> Content) {
    self.content = { _ in content() }
  }

  public init(@ViewSequence _ content: @escaping (GeometryProxy) -> Content) {
    self.content = content
  }

  public typealias Body = Never

  private let content: (GeometryProxy) -> Content
  private let proxy = GeometryProxy()
}

extension Group: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let view = ViewBuilder(content: content(proxy)).buildView(context: context)
    proxy._width = view.effectiveWidthGetter
    proxy._height = view.effectiveHeightGetter
    return view
  }
}

@MainActor
@resultBuilder
public struct ViewSequence {
  public static func buildBlock<each Content>(
    _ content: repeat each Content
  ) -> TupleView<repeat each Content> where repeat each Content : View {
    .init(content: (repeat each content))
  }
}

public struct TupleView<each Content>: View where repeat each Content: View {
  public typealias Body = Never

  let content: (repeat each Content)
}

extension TupleView: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let view = CoreView(context: context)

    var subviews: [CoreView] = []
    for subview in repeat ViewBuilder(content: each content).buildView(context: context) {
      subviews.append(subview)
    }
    view.subviews = { subviews }
    return view
  }
}
