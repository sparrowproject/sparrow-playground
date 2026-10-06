import SparrowUICore

final class EventInterceptor: EventRouter {
  init(sink: EventRouter) {
    self.sink = sink
  }

  enum Policy {
    case allow
    case block
  }

  var onPointerDown: ((CorePointerEvent) -> Policy)?
  var onPointerUp: ((CorePointerEvent) -> Policy)?
  var onPointerEntered: ((CorePointerEvent) -> Policy)?
  var onPointerExited: ((CorePointerEvent) -> Policy)?
  var onPointerMoved: ((CorePointerEvent) -> Policy)?
  var onPointerDragged: ((CorePointerDragEvent) -> Policy)?
  var onPointerWheel: ((CorePointerWheelEvent) -> Policy)?
  var onKeyDown: ((CoreKeyEvent) -> Policy)?
  var onKeyUp: ((CoreKeyEvent) -> Policy)?
  #if os(Windows)
  var onPointerCaptureLost: (() -> Policy)?
  #endif

  func handlePointerDown(event: CorePointerEvent) {
    if onPointerDown?(event) == .block {
      return
    }
    sink.handlePointerDown(event: event)
  }

  func handlePointerUp(event: CorePointerEvent) {
    if onPointerUp?(event) == .block {
      return
    }
    sink.handlePointerUp(event: event)
  }

  func handlePointerEntered(event: CorePointerEvent) {
    if onPointerEntered?(event) == .block {
      return
    }
    sink.handlePointerEntered(event: event)
  }

  func handlePointerExited(event: CorePointerEvent) {
    if onPointerExited?(event) == .block {
      return
    }
    sink.handlePointerExited(event: event)
  }

  func handlePointerMoved(event: CorePointerEvent) {
    if onPointerMoved?(event) == .block {
      return
    }
    sink.handlePointerMoved(event: event)
  }

  func handlePointerDragged(event: CorePointerDragEvent) {
    if onPointerDragged?(event) == .block {
      return
    }
    sink.handlePointerDragged(event: event)
  }

  func handlePointerWheel(event: CorePointerWheelEvent) {
    if onPointerWheel?(event) == .block {
      return
    }
    sink.handlePointerWheel(event: event)
  }

  func handleKeyDown(event: CoreKeyEvent) {
    if onKeyDown?(event) == .block {
      return
    }
    sink.handleKeyDown(event: event)
  }

  func handleKeyUp(event: CoreKeyEvent) {
    if onKeyUp?(event) == .block {
      return
    }
    sink.handleKeyUp(event: event)
  }

  #if os(Windows)
  func handlePointerCaptureLost() {
    if onPointerCaptureLost?() == .block {
      return
    }
    sink.handlePointerCaptureLost()
  }
  #endif

  func updateHoveredViews(event: CorePointerEvent) {
    sink.updateHoveredViews(event: event)
  }

  private let sink: EventRouter
}