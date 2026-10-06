import Foundation
import OrderedCollections
import SparrowUICore

@MainActor
protocol EventRouter: AnyObject {
  func handlePointerDown(event: CorePointerEvent)
  func handlePointerUp(event: CorePointerEvent)
  func handlePointerEntered(event: CorePointerEvent)
  func handlePointerExited(event: CorePointerEvent)
  func handlePointerMoved(event: CorePointerEvent)
  func handlePointerDragged(event: CorePointerDragEvent)
  func handlePointerWheel(event: CorePointerWheelEvent)
  func handleKeyDown(event: CoreKeyEvent)
  func handleKeyUp(event: CoreKeyEvent)

  #if os(Windows)
  func handlePointerCaptureLost()
  #endif

  func updateHoveredViews(event: CorePointerEvent)
}

final class DefaultEventRouter: EventRouter {
  init(rootView: CoreView, onSetCursor: @escaping (Cursor?) -> Void) {
    self.rootView = rootView
    self.onSetCursor = onSetCursor
  }

  var capturedView: CoreView?  {
    didSet {
      guard capturedView != oldValue else { return }
      if let capturedView {
        capturedView.reportCursor = { [weak self] in
          self?.onSetCursor($0)
        }
      } else {
        oldValue?.reportCursor = nil
        onSetCursor(nil)
      }
    }
  }

  func handlePointerDown(event: CorePointerEvent) {
    // Do not require a `pointerDown` handler on the hit test. This way if a view
    // is only interested in `pointerDrag` or `pointerUp`, it can still get those.
    // This way we always have a captured view when the hosting view has capture.
    // XXX - fix this comment!
    if let targetView = rootView.hitTest(at: event.locationInRoot, matchingAnyOf: [.pointerDown, .pointerDragged]) {
      capturedView = targetView
      dispatchEvent(event, targeting: targetView, as: \.onPointerDown)
    }
  }

  func handlePointerUp(event: CorePointerEvent) {
    if let capturedView {
      dispatchEvent(event, targeting: capturedView, as: \.onPointerUp)
      self.capturedView = nil
    } else if let targetView = rootView.hitTest(at: event.locationInRoot, matchingAnyOf: [.pointerUp]) {
      dispatchEvent(event, targeting: targetView, as: \.onPointerUp)
    }
  }

  func handlePointerEntered(event: CorePointerEvent) {
    updateHoveredViews(for: event, flushUpdates: true)
  }

  func handlePointerExited(event: CorePointerEvent) {
    // NOTE: `handlePointerExited` can be generated even when the mouse is still over the view, such as
    // when it loses focus due to a child window taking focus. In this case, we cannot hit-test, and
    // instead just need to force the `pointerExited` event.

    scheduler.flushUpdates()
    for view in hoveredViews {
      view.onPointerExited.dispatchEvent(event)
    }
    hoveredViews = []
  }

  func handlePointerMoved(event: CorePointerEvent) {
    updateHoveredViews(for: event, flushUpdates: true)

    // Hit test for a cursor.
    let cursor: Cursor? =
      if let targetView = rootView.hitTest(at: event.locationInRoot, matchingAnyOf: [.hasCursor]) {
        targetView.activeCursor
      } else {
        nil
      }
    onSetCursor(cursor)

    if let targetView = rootView.hitTest(at: event.locationInRoot, matchingAnyOf: [.pointerMoved]) {
      dispatchEvent(event, targeting: targetView, as: \.onPointerMoved)
    }
  }

  func handlePointerDragged(event: CorePointerDragEvent) {
    if let capturedView {
      dispatchEvent(event, targeting: capturedView, as: \.onPointerDragged)
    } else {
      handlePointerMoved(event: event)
    }
  }
 
  func handlePointerWheel(event: CorePointerWheelEvent) {
    if let targetView = rootView.hitTest(at: event.locationInRoot, matchingAnyOf: .pointerWheel) {
      dispatchEvent(event, targeting: targetView, as: \.onPointerWheel)
    }
  }

  func handleKeyDown(event: CoreKeyEvent) {
    if let focusedView = context.focusedView {
      dispatchEvent(event, targeting: focusedView, as: \.onKeyDown)
    }
  }

  func handleKeyUp(event: CoreKeyEvent) {
    if let focusedView = context.focusedView {
      dispatchEvent(event, targeting: focusedView, as: \.onKeyUp)
    }
  }

  func updateHoveredViews(event: CorePointerEvent) {
    updateHoveredViews(for: event, flushUpdates: false)
  }

  #if os(Windows)
  func handlePointerCaptureLost() {
    capturedView = nil
  }
  #endif

  private let rootView: CoreView
  private let onSetCursor: (Cursor?) -> Void

  private var hoveredViews = OrderedSet<CoreView>()

  private var context: CoreViewContext {
    rootView.context
  }

  private var scheduler: CoreScheduler {
    rootView.context.scheduler
  }

  private func dispatchEvent<Event, HandlerSet>(
    _ event: Event,
    targeting: CoreView,
    as handlerSet: HandlerSet,
  ) where Event: CoreEvent, HandlerSet: KeyPath<CoreView, CoreEventHandlerSet<Event>> {
    scheduler.flushUpdates()
    var view: CoreView? = targeting
    repeat {
      if let handler = view?[keyPath: handlerSet], !handler.isEmpty {
        handler.dispatchEvent(event)
        if event.handled {
          break
        }
      }
      view = view?.superview
    }
    while view != nil
  }

  private func updateHoveredViews(
    for event: CorePointerEvent,
    flushUpdates: Bool,
  ) {
    if flushUpdates {
      scheduler.flushUpdates()
    }

    var targetViews = OrderedSet<CoreView>()
    rootView.hitTestMany(
      at: event.locationInRoot,
      matchingAnyOf: [.pointerEnter, .pointerExit],
      addingTo: &targetViews,
    )

    let diff = targetViews.difference(from: hoveredViews)

    // Update removals first.

    for change in diff {
      switch change {
      case .insert:
        break
      case .remove(_, let view, _):
        view.onPointerExited.dispatchEvent(event)
      }
    }

    for change in diff {
      switch change {
      case .insert(_, let view, _):
        view.onPointerEntered.dispatchEvent(event)
      case .remove:
        break
      }
    }

    hoveredViews = targetViews
  }
}
