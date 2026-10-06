import SparrowUICore

@MainActor
public protocol ViewModifier {
  associatedtype Body: View

  func body(content: Content) -> Body

  typealias Content = _ViewModifier_Content<Self>
}

extension ViewModifier where Self.Body == Never {
  public func body(content: Content) -> Never { fatalError("No Body") }
}

// MARK: _ViewModifier_Content

@MainActor
public struct _ViewModifier_Content<Modifier> where Modifier: ViewModifier {
  init<Content: View>(content: Content) {
    _builder = ViewBuilder<Content>(content: content)
  }
  private let _builder: AnyViewBuilder
}

extension _ViewModifier_Content: View {
  public typealias Body = Never
}

extension _ViewModifier_Content: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    _builder.buildView(context: context)
  }
}

// MARK: View.modifier

extension View {
  public func modifier<Modifier>(_ modifier: Modifier) -> ModifiedContent<Self, Modifier> {
    .init(content: self, modifier: modifier)
  }
}

// MARK: ModifiedContent

@MainActor
public struct ModifiedContent<Content, Modifier> {
  public var content: Content
  public var modifier: Modifier
}

extension ModifiedContent: View where Content: View, Modifier: ViewModifier {
  public typealias Body = Never
}

extension ModifiedContent: PrimitiveView where Content: View, Modifier: ViewModifier {
  func buildView(context: CoreViewContext) -> CoreView {
    if let primitive = modifier as? PrimitiveViewModifier {
      let view = ViewBuilder(content: content).buildView(context: context)
      primitive.apply(to: view)
      return view
    } else {
      return ViewBuilder(content: modifier.body(content: .init(content: content))).buildView(context: context)
    }
  }
}

