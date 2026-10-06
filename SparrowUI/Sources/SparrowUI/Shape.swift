import Foundation
import SparrowUICore
import SparrowUIFoundation

public protocol Shape: View {
  func path(in rect: CGRect) -> Path
}

public struct _ShapeView<S: Shape>: View {
  public typealias Body = Never

  let shape: S
}

extension Shape {
  public var body: _ShapeView<Self> {
    .init(shape: self)
  }
}

extension _ShapeView: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let view = CoreShapeView(context: context)
    view.path = { shape.path(in: .init(origin: .zero, size: $0)) }
    return view
  }
}

// MARK: fill

extension Shape {
  public func fill(_ color: @autoclosure @MainActor @escaping () -> Color) -> some Shape {
    _ShapeWithFill(shape: self, color: color)
  }
}

@MainActor
public struct _ShapeWithFill<S: Shape>: Shape {
  let shape: S
  let color: @MainActor () -> Color

  public func path(in rect: CGRect) -> Path {
    fatalError("Not reached!")
  }
}

extension _ShapeWithFill: View {
  public typealias Body = Never
}

extension _ShapeWithFill: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let view = ViewBuilder(content: shape).buildView(context: context)
    let colorSchemeGetter = view.effectiveColorSchemeGetter
    (view as! CoreShapeView).fillColor = { color().resolved(with: colorSchemeGetter()) }
    return view
  }
}

// MARK: stroke

extension Shape {
  public func stroke(_ color: @autoclosure @MainActor @escaping () -> Color) -> some Shape {
    _ShapeWithStroke(shape: self, color: color)
  }
}

@MainActor
public struct _ShapeWithStroke<S: Shape>: Shape {
  let shape: S
  let color: @MainActor () -> Color

  public func path(in rect: CGRect) -> Path {
    fatalError("Not reached!")
  }
}

extension _ShapeWithStroke: View {
  public typealias Body = Never
}

extension _ShapeWithStroke: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let view = ViewBuilder(content: shape).buildView(context: context)
    let colorSchemeGetter = view.effectiveColorSchemeGetter
    (view as! CoreShapeView).strokeColor = { color().resolved(with: colorSchemeGetter()) }
    return view
  }
}
