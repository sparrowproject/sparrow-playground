import Foundation
import SparrowUICore
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WindowsFoundation
import WinUI
#endif

@MainActor
public struct PointerLocation: Sendable {
  public enum CoordinateSystem {
    case view
    case host
    case window
  }

  init(event: CorePointerEvent, view: CoreView) {
    self.event = event
    self.view = view
  }

  // TODO: Add this back if needed.
  // public var displayPoint: DisplayPoint {
  //   let pointInWindow = point(in: .window)
  //   #if os(macOS)
  //   return view.context.containingNSWindow!.convertPoint(toScreen: pointInWindow)
  //   #elseif os(Windows)
  //   // TODO
  //   #endif
  // }

  public func point(in coordinateSystem: CoordinateSystem) -> CGPoint {
    switch coordinateSystem {
    case .view:
      let rect = view.rectInRootView!
      return CGPoint(
        x: event.locationInRoot.x - rect.minX,
        y: event.locationInRoot.y - rect.minY,
      )
    case .host:
      return event.locationInRoot
    case .window:
      #if os(macOS)
      let containingNSView = view.context.containingNSView!
      return containingNSView.convert(event.locationInRoot, to: nil)
      #elseif os(Windows)
      let containingUIElement = view.context.containingUIElement!
      let transform = try! containingUIElement.transformToVisual(nil)!
      let transformedPoint = try! transform.transformPoint(.init(event.locationInRoot))
      return .init(transformedPoint)
      #else
      fatalError("Unsupported platform")
      #endif
    }
  }

  public func unitPoint(in coordinateSystem: CoordinateSystem) -> UnitPoint {
    let point = point(in: coordinateSystem)
    let size = size(of: coordinateSystem)
    precondition(size.width != 0 && size.height != 0)
    return UnitPoint(x: point.x / size.width, y: point.y / size.height)
  }

  private let event: CorePointerEvent
  private let view: CoreView

  private func size(of coordinateSystem: CoordinateSystem) -> CGSize {
    switch coordinateSystem {
    case .view:
      return view.effectiveSizeGetter()
    case .host:
      #if os(macOS)
      return view.context.containingNSView!.bounds.size
      #elseif os(Windows)
      return containingFrameworkElementSize()
      #else
      fatalError("Unsupported platform")
      #endif
    case .window:
      #if os(macOS)
      return view.context.containingNSWindow!.contentLayoutRect.size
      #elseif os(Windows)
      let containingUIElement = view.context.containingUIElement!
      let transform = try! containingUIElement.transformToVisual(nil)!
      let hostSize = containingFrameworkElementSize()
      let hostBounds = CGRect(origin: .zero, size: hostSize)
      let transformedBounds = try! transform.transformBounds(.init(hostBounds))
      return CGSize(width: CGFloat(transformedBounds.width), height: CGFloat(transformedBounds.height))
      #else
      fatalError("Unsupported platform")
      #endif
    }
  }

  #if os(Windows)
  private func containingFrameworkElementSize() -> CGSize {
    let containingUIElement = view.context.containingUIElement as! FrameworkElement
    return .init(
      width: CGFloat(containingUIElement.actualWidth),
      height: CGFloat(containingUIElement.actualHeight),
    )
  }
  #endif
}
