import SparrowUICore

// MARK: AnyViewBuilder

@MainActor
protocol AnyViewBuilder {
  func buildView(context: CoreViewContext) -> CoreView
}

// MARK: _ViewBuilder

@MainActor
struct ViewBuilder<Content: View> {
  let content: Content
}

extension ViewBuilder: AnyViewBuilder {
  func buildView(context: CoreViewContext) -> CoreView {
    if let primitive = content as? PrimitiveView {
      primitive.buildView(context: context)
    } else {
      ViewBuilder<Content.Body>(content: content.body).buildView(context: context)
    }
  }
}

// MARK: PrimitiveView

@MainActor
protocol PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView
}

// MARK: PrimitiveViewModifier

@MainActor
protocol PrimitiveViewModifier {
  func apply(to view: CoreView)
}
