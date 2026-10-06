#if os(macOS)
import AppKit
import SparrowUICore

public protocol NSViewRepresentable: View {
  associatedtype NSViewType: NSView

  func makeNSView() -> NSViewType
  func makeNSView(context: CoreViewContext, associatedView: CoreView) -> NSViewType

  static func tearDownNSView(_: NSViewType)
}

extension NSViewRepresentable {
  public func makeNSView() -> NSViewType {
    fatalError()
  }

  public func makeNSView(context _: CoreViewContext, associatedView _: CoreView) -> NSViewType {
    makeNSView()
  }
}

extension NSViewRepresentable {
  public var body: some View {
    _NSViewRepresentable_Content(representable: self)
  }
}

private struct _NSViewRepresentable_Content<Representable: NSViewRepresentable>: View {
  typealias Body = Never

  let representable: Representable
}

extension _NSViewRepresentable_Content: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    CoreEmbeddedView(
      context: context,
      makePlatformView: {
        representable.makeNSView(context: context, associatedView: $0)
      },
      tearDownPlatformView: {
        Representable.tearDownNSView($0 as! Representable.NSViewType)
      }
    )
  }
}
#endif