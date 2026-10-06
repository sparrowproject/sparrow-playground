public enum Cursor: Sendable, Equatable {
  case arrow
  case iBeam
  case crosshair
  case pointingHand
  // case openHand
  // case closedHand
  case resizeLeftRight
  case resizeUpDown
  // case resizeUpLeftDownRight
  // case resizeUpRightDownLeft
  // case move
  case operationNotAllowed
  // case dragLink
  // case dragCopy
}

#if os(macOS)
import AppKit

extension NSCursor {
  public static func from(_ cursor: Cursor) -> NSCursor {
    switch cursor {
    case .arrow:
      .arrow
    case .iBeam:
      .iBeam
    case .crosshair:
      .crosshair
    case .pointingHand:
      .pointingHand
    case .resizeLeftRight:
      .resizeLeftRight
    case .resizeUpDown:
      .resizeUpDown
    // case .resizeUpLeftDownRight:
    //   .resizeUpLeftDownRight
    // case .resizeUpRightDownLeft:
    //   .resizeUpRightDownLeft
    // case .move:
    //   .move
    case .operationNotAllowed:
      .operationNotAllowed
    }
  }
}
#endif

#if os(Windows)
import WinAppSDK

extension InputSystemCursorShape {
  public static func from(_ cursor: Cursor) -> Self {
    switch cursor {
    case .arrow:
      .arrow
    case .iBeam:
      .ibeam
    case .crosshair:
      .cross
    case .pointingHand:
      .hand
    case .resizeLeftRight:
      .sizeWestEast
    case .resizeUpDown:
      .sizeNorthSouth
    // case .resizeUpLeftDownRight:
    //   .sizeNorthwestSoutheast
    // case .resizeUpRightDownLeft:
    //   .sizeNortheastSouthwest
    // case .move:
    //   .sizeAll
    case .operationNotAllowed:
      .universalNo
    }
  }
}

#endif