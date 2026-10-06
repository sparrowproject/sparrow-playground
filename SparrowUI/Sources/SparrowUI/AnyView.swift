import SparrowUICore

public struct AnyView: View {
  public init<Content: View>(_ content: Content) {
    buildableView = AnyBuildableViewImpl(content: content)
  }

  public typealias Body = Never

  private let buildableView: AnyBuildableView
}

@MainActor
private protocol AnyBuildableView {
  func buildView(context: CoreViewContext) -> CoreView
}

private struct AnyBuildableViewImpl<Content: View>: AnyBuildableView {
  let content: Content

  func buildView(context: CoreViewContext) -> CoreView {
    ViewBuilder(content: content).buildView(context: context)
  }
}

extension AnyView: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    buildableView.buildView(context: context)
  }
}
