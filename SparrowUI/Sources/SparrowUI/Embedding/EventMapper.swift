import Foundation
import SparrowUICore

#if os(macOS)
import AppKit
#elseif os(Windows)
import SparrowUIFoundation
import WindowsFoundation
import WinSDK
import WinUI
#endif

final class EventMapper: EventRouter {
  init(from sourceView: HostingView, to targetView: HostingView) {
    self.sourceView = sourceView
    self.targetView = targetView
  }

  func handlePointerDown(event: CorePointerEvent) {
    let mappedEvent = mapPointerEvent(event)
    targetView.eventRouter.handlePointerDown(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  func handlePointerUp(event: CorePointerEvent) {
    let mappedEvent = mapPointerEvent(event)
    targetView.eventRouter.handlePointerUp(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  func handlePointerEntered(event: CorePointerEvent) {
    let mappedEvent = mapPointerEvent(event)
    targetView.eventRouter.handlePointerEntered(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  func handlePointerExited(event: CorePointerEvent) {
    let mappedEvent = mapPointerEvent(event)
    targetView.eventRouter.handlePointerExited(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  func handlePointerMoved(event: CorePointerEvent) {
    let mappedEvent = mapPointerEvent(event)
    targetView.eventRouter.handlePointerMoved(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  func handlePointerDragged(event: CorePointerDragEvent) {
    let mappedEvent = mapPointerDragEvent(event)
    targetView.eventRouter.handlePointerDragged(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  func handlePointerWheel(event: CorePointerWheelEvent) {
    let mappedEvent = mapPointerWheelEvent(event)
    targetView.eventRouter.handlePointerWheel(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  func handleKeyDown(event: CoreKeyEvent) {
    targetView.eventRouter.handleKeyDown(event: event)
  }

  func handleKeyUp(event: CoreKeyEvent) {
    targetView.eventRouter.handleKeyUp(event: event)
  }

  #if os(Windows)
  func handlePointerCaptureLost() {
    targetView.eventRouter.handlePointerCaptureLost()
  }
  #endif

  func updateHoveredViews(event: CorePointerEvent) {
    let mappedEvent = mapPointerEvent(event)
    targetView.eventRouter.updateHoveredViews(event: mappedEvent)
    event.handled = mappedEvent.handled
  }

  private let sourceView: HostingView
  private let targetView: HostingView

  private func mapPointerEvent(_ event: CorePointerEvent) -> CorePointerEvent {
    .init(
      locationInRoot: mapPoint(event.locationInRoot),
      buttons: event.buttons,
      modifierFlags: event.modifierFlags,
    )
  }

  private func mapPointerDragEvent(_ event: CorePointerDragEvent) -> CorePointerDragEvent {
    .init(
      locationInRoot: mapPoint(event.locationInRoot),
      buttons: event.buttons,
      modifierFlags: event.modifierFlags,
      deltaX: event.deltaX,
      deltaY: event.deltaY,
    )
  }

  private func mapPointerWheelEvent(_ event: CorePointerWheelEvent) -> CorePointerWheelEvent {
    .init(
      locationInRoot: mapPoint(event.locationInRoot),
      buttons: event.buttons,
      modifierFlags: event.modifierFlags,
      deltaX: event.deltaX,
      deltaY: event.deltaY,
      hasPreciseScrollDeltas: event.hasPreciseScrollDeltas,
    )
  }

  private func mapPoint(_ point: CGPoint) -> CGPoint {
    #if os(macOS)
    mapPointBetweenViews(
      point,
      fromView: sourceView as! NSView,
      toView: targetView as! NSView,
    )
    #elseif os(Windows)
    mapPointBetweenElements(
      point,
      fromElement: sourceView as! UIElement,
      toElement: targetView as! UIElement,
    )
    #endif
  }
}

#if os(macOS)
@MainActor
private func mapPointBetweenViews(
  _ point: CGPoint,
  fromView: NSView,
  toView: NSView,
) -> CGPoint {
  guard let fromWindow = fromView.window else {
    assertionFailure("fromView should have a non-nil window")
    return point
  }
  guard let toWindow = toView.window else {
    assertionFailure("toView should have a non-nil window")
    return point
  }

  // Fast path in case both are in the same window.
  if fromWindow === toWindow {
    return fromView.convert(point, to: toView)
  }

  let windowPoint = fromView.convert(point, to: nil)
  let screenPoint = fromWindow.convertPoint(toScreen: windowPoint)

  let toWindowPoint = toWindow.convertPoint(fromScreen: screenPoint)
  return toView.convert(toWindowPoint, from: nil)
}
#endif

#if os(Windows)
private func mapPointBetweenElements(
  _ point: CGPoint,
  fromElement sourceElement: UIElement,
  toElement destinationElement: UIElement,
) -> CGPoint {
  guard let sourceRoot = sourceElement.xamlRoot else {
    assertionFailure("sourceElement should have a non-nil xamlRoot")
    return point
  }
  guard let sourceHwnd = sourceElement.appWindow?.getHWND() else {
    assertionFailure("sourceElement should have a non-nil parent HWND")
    return point
  }

  guard let destinationRoot = destinationElement.xamlRoot else {
    assertionFailure("destinationElement should have a non-nil xamlRoot")
    return point
  }
  guard let destinationHwnd = destinationElement.appWindow?.getHWND() else {
    assertionFailure("destinationElement should have a non-nil parent HWND")
    return point
  }

  let sourceToRoot = try! sourceElement.transformToVisual(nil)!
  let pointInSourceRoot = try! sourceToRoot.transformPoint(.init(point))

  let sourceScale = sourceRoot.rasterizationScale

  var screenPoint = POINT(
    x: LONG((pointInSourceRoot.x * Float(sourceScale)).rounded()),
    y: LONG((pointInSourceRoot.y * Float(sourceScale)).rounded())
  )

  guard ClientToScreen(sourceHwnd, &screenPoint) else {
    assertionFailure("ClientToScreen failed!")
    return point
  }

  guard ScreenToClient(destinationHwnd, &screenPoint) else {
    assertionFailure("ScreenToClient failed!")
    return point
  }

  let destinationScale = destinationRoot.rasterizationScale

  let pointInDestinationRoot = Point(
    x: Float(screenPoint.x) / Float(destinationScale),
    y: Float(screenPoint.y) / Float(destinationScale),
  )

  let destinationToRoot = try! destinationElement.transformToVisual(nil)!

  let destinationPoint = try! destinationToRoot.inverse.transformPoint(
    pointInDestinationRoot
  )

  return .init(destinationPoint)
}
#endif