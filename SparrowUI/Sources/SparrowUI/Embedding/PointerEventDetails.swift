import Foundation
import SparrowUICore

struct PointerEventDetails {
  let location: CGPoint
  let buttons: PointerButtons
  let modifiers: Keystroke.ModifierFlags
}

extension CorePointerEvent {
  convenience init(details: PointerEventDetails) {
    self.init(
      locationInRoot: details.location,
      buttons: details.buttons,
      modifierFlags: details.modifiers,
    )
  }
}

extension CorePointerDragEvent {
  convenience init(details: PointerEventDetails, deltaX: CGFloat, deltaY: CGFloat) {
    self.init(
      locationInRoot: details.location,
      buttons: details.buttons,
      modifierFlags: details.modifiers,
      deltaX: deltaX,
      deltaY: deltaY,
    )
  }
}

extension CorePointerWheelEvent {
  convenience init(details: PointerEventDetails, deltaX: CGFloat, deltaY: CGFloat, hasPreciseScrollDeltas: Bool) {
    self.init(
      locationInRoot: details.location,
      buttons: details.buttons,
      modifierFlags: details.modifiers,
      deltaX: deltaX,
      deltaY: deltaY,
      hasPreciseScrollDeltas: hasPreciseScrollDeltas,
    )
  }
}