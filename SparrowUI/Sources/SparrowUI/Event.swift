import Foundation
import SparrowUICore
import SparrowUIFoundation

@MainActor
public protocol Event {
  var handled: Bool { get nonmutating set }
  var modifierFlags: Keystroke.ModifierFlags { get }
}

public protocol PointerEvent: Event {
  var location: PointerLocation { get }
  var buttons: PointerButtons { get }
}

public protocol PointerDragEvent: PointerEvent {
  var delta: CGPoint { get }
}

public protocol PointerWheelEvent: PointerEvent {
  var delta: CGPoint { get }
  var hasPreciseScrollDeltas: Bool { get }
}

public protocol KeyEvent: Event {
  var key: Keystroke { get }
}

// MARK: Implementation

@MainActor
protocol _Event {
  associatedtype CoreEventType: CoreEvent
  var event: CoreEventType { get }
}

extension _Event where Self: Event {
  var handled: Bool {
    get { event.handled }
    nonmutating set { event.handled = newValue }
  }

  var modifierFlags: Keystroke.ModifierFlags {
    event.modifierFlags
  }
}

@MainActor
protocol _PointerEvent {
  associatedtype CorePointerEventType: CorePointerEvent

  var event: CorePointerEventType { get }
  var view: CoreView { get }
}

extension _PointerEvent where Self: PointerEvent {
  var location: PointerLocation {
    .init(event: event, view: view)
  }

  var buttons: PointerButtons {
    event.buttons
  }
}

struct _AnyPointerEvent: _PointerEvent, _Event {
  let event: CorePointerEvent
  let view: CoreView
}

extension _AnyPointerEvent: PointerEvent {}

struct _PointerDragEvent: _PointerEvent, _Event {
  let event: CorePointerDragEvent
  let view: CoreView
}

extension _PointerDragEvent: PointerDragEvent {
  var delta: CGPoint {
    .init(x: event.deltaX, y: event.deltaY)
  }
}

struct _PointerWheelEvent: _PointerEvent, _Event {
  let event: CorePointerWheelEvent
  let view: CoreView
}

extension _PointerWheelEvent: PointerWheelEvent {
  var delta: CGPoint {
    .init(x: event.deltaX, y: event.deltaY)
  }

  var hasPreciseScrollDeltas: Bool {
    event.hasPreciseScrollDeltas
  }
}

@MainActor
struct _KeyEvent: _Event {
  let event: CoreKeyEvent
}

extension _KeyEvent: KeyEvent {
  var key: Keystroke {
    event.key
  }
}