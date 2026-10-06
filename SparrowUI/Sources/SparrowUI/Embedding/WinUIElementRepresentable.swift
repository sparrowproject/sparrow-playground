#if os(Windows)
import SparrowUICore
import WinUI

public protocol WinUIElementRepresentable: View {
  associatedtype UIElementType: UIElement

  func makeUIElement() -> UIElementType
  func makeUIElement(context: CoreViewContext, associatedView: CoreView) -> UIElementType

  static func tearDownUIElement(_: UIElementType)
}

extension WinUIElementRepresentable {
  public func makeUIElement() -> UIElementType {
    fatalError()
  }

  public func makeUIElement(context _: CoreViewContext, associatedView _: CoreView) -> UIElementType {
    makeUIElement()
  }
}

extension WinUIElementRepresentable {
  public var body: some View {
    _WinUIElementRepresentable_Content(representable: self)
  }
}

private struct _WinUIElementRepresentable_Content<Representable: WinUIElementRepresentable>: View {
  typealias Body = Never

  let representable: Representable
}

extension _WinUIElementRepresentable_Content: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    CoreEmbeddedView(
      context: context,
      makePlatformView: {
        representable.makeUIElement(context: context, associatedView: $0)
      },
      tearDownPlatformView: {
        Representable.tearDownUIElement($0 as! Representable.UIElementType)
      }
    )
  }
}

#endif