import Foundation
import SparrowUIFoundation

// MARK: CoreEvent

public class CoreEvent {
  public init(modifierFlags: Keystroke.ModifierFlags) {
    self.modifierFlags = modifierFlags
  }

  /// An integer bit field that indicates the pressed modifier keys.
  public let modifierFlags: Keystroke.ModifierFlags

  /// Set to true to indicate if the event has handled. Used to stop event propagation.
  public var handled = false
}

// MARK: CorePointerEvent

public class CorePointerEvent: CoreEvent {
  public init(
    locationInRoot: CGPoint,
    buttons: PointerButtons,
    modifierFlags: Keystroke.ModifierFlags,
  ) {
    self.locationInRoot = locationInRoot
    self.buttons = buttons
    super.init(modifierFlags: modifierFlags)
  }
  
  public let locationInRoot: CGPoint
  public let buttons: PointerButtons
}

// MARK: CorePointerDragEvent

public final class CorePointerDragEvent: CorePointerEvent {
  public init(
    locationInRoot: CGPoint,
    buttons: PointerButtons,
    modifierFlags: Keystroke.ModifierFlags,
    deltaX: CGFloat,
    deltaY: CGFloat,
  ) {
    self.deltaX = deltaX
    self.deltaY = deltaY
    super.init(
      locationInRoot: locationInRoot,
      buttons: buttons,
      modifierFlags: modifierFlags,
    )
  }

  public let deltaX: CGFloat
  public let deltaY: CGFloat
}

// MARK: CorePointerWheelEvent

public final class CorePointerWheelEvent: CorePointerEvent {
  public init(
    locationInRoot: CGPoint,
    buttons: PointerButtons,
    modifierFlags: Keystroke.ModifierFlags,
    deltaX: CGFloat,
    deltaY: CGFloat,
    hasPreciseScrollDeltas: Bool,
  ) {
    self.deltaX = deltaX
    self.deltaY = deltaY
    self.hasPreciseScrollDeltas = hasPreciseScrollDeltas
    super.init(
      locationInRoot: locationInRoot,
      buttons: buttons,
      modifierFlags: modifierFlags,
    )
  }

  public let deltaX: CGFloat
  public let deltaY: CGFloat
  public let hasPreciseScrollDeltas: Bool
}

// MARK: CoreKeyEvent

public final class CoreKeyEvent: CoreEvent {
  public init(key: Keystroke, modifierFlags: Keystroke.ModifierFlags) {
    self.key = key
    super.init(modifierFlags: modifierFlags)
  }
  public let key: Keystroke
}

// MARK: CoreEventHandlerSet

@MainActor
public final class CoreEventHandlerSet<EventType> where EventType: CoreEvent {
  init() {}

  public var isEmpty: Bool {
    handlers.isEmpty
  }

  public func add(_ handler: @escaping (EventType) -> Void) {
    handlers.append(handler)
  }

  /// Dispatch an event to all registered event handlers in LIFO order, stopping
  /// if `handled` is true. Event handlers have the ability to prevent the event
  /// from being seen by earlier added handlers.
  public func dispatchEvent(_ event: EventType) {
    for handler in handlers.reversed() {
      if event.handled {
        break
      }
      handler(event)
    }
  }

  private var handlers = [(EventType) -> Void]()
}
