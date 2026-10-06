import SparrowUICore
import SparrowUIFoundation

extension View {
  /// Opens a popover at a particular anchor point with given content.
  public func popover<Content: View>(
    isPresented: Binding<Bool>,
    preferredAnchor: @autoclosure @MainActor @escaping () -> PositionalAnchor,
    style: @autoclosure @MainActor @escaping () -> PopoverStyle = .init(),
    content: @MainActor @escaping () -> Content,
  ) -> some View {
    modifier(_PopoverModifier(
      isPresented: isPresented,
      preferredAnchor: preferredAnchor,
      style: style,
      content: content,
    ))
  }
}

/*

menuButton
  .popup(MainMenu(), preferredAnchor: .anchorTo(.bounds, place: .below(.alignment: .trailing)))

tabView
  .contextPopup(TabMenu(), preferredAnchor: .anchorTo(.point, place: .below(.alignment: .leading)))
  .popup(isPresented: $showThumbnail, preferredAnchor: .anchorTo(.bounds, place: .below(.alignment: .leading)))

backButton
  .contextPopup(BackMenu(), preferredAnchor: .anchorTo(.bounds, place: .below(.alignment: .leading)))

extensionButton
  .popup(ExtensionPopup(), preferredAnchor: .anchorTo(.bounds, place: .below(.alignment: .leading)))

statusBubbleAnchor
  .nonInteractivePopup(isPresented: $showStatusBubble, StatusView(), preferredAnchor: .anchorTo(.bounds, place: .below(.alignment: .leading)))

*/

@MainActor
protocol _PopoverImpl {
  var isPresented: Binding<Bool> { get }
  var windowRect: DisplayRect? { get }
  var state: _PopoverState { get }
}

@MainActor
protocol _PopoverState: AnyObject {
  var transientZoneTask: Task<Void, Never>? { get set }
  var lastLocationOnScreen: DisplayPoint? { get set }
}

enum _PopoverHitTestResult {
  case anchorView
  case popoverWindow
  case transientZone
}

enum _PopoverWindowPosition {
  case left
  case right
  case above
  case below
}

extension _PopoverImpl {
  func handlePointerUpdate(locationOnScreen: DisplayPoint, anchorView: CoreView) {
    switch hitTest(locationOnScreen: locationOnScreen, anchorView: anchorView) {
    case .none:
      state.transientZoneTask?.cancel()
      state.transientZoneTask = nil
      state.lastLocationOnScreen = nil
      isPresented.set(false)
    case .transientZone:
      state.transientZoneTask?.cancel()
      if !isMovingTowardPopoverWindow(locationOnScreen: locationOnScreen) {
        state.transientZoneTask = nil
        isPresented.set(false)
      } else {
        state.transientZoneTask = .init {
          try? await Task.sleep(for: .seconds(0.2))
          guard !Task.isCancelled else { return }
          isPresented.set(false)
          state.transientZoneTask = nil
        }
      }
      state.lastLocationOnScreen = locationOnScreen

    case .anchorView, .popoverWindow:
      state.transientZoneTask?.cancel()
      state.transientZoneTask = nil
      state.lastLocationOnScreen = nil
    }

    anchorView.context.scheduler.flushUpdates()
  }

  func hitTest(locationOnScreen: DisplayPoint, anchorView: CoreView) -> _PopoverHitTestResult? {
    guard
      let windowRect,
      let anchorRect = anchorView.rectOnScreen
    else {
      return nil
    }

    if windowRect.contains(locationOnScreen) {
      return .popoverWindow
    }

    if anchorRect.contains(locationOnScreen) {
      return .anchorView
    }

    // Check if `locationOnScreen` is contained within one of the transient zones.
    // A popover can be moved to a fallback position to keep it on screen, so derive its
    // position from the final frames. For diagonally separated frames, use the pair of
    // facing edges with the smallest gap.
    let positions: [(gap: DisplayUnit, position: _PopoverWindowPosition)] = [
      (anchorRect.minX - windowRect.maxX, .left),
      (windowRect.minX - anchorRect.maxX, .right),
      (windowRect.minY - anchorRect.maxY, .above),
      (anchorRect.minY - windowRect.maxY, .below),
    ]
    let separatedPositions = positions.filter { $0.gap >= 0 }

    let position = if separatedPositions.isEmpty {
      // When the rectangles overlap on both axes, the least-negative gap identifies
      // the pair of facing edges with the least overlap.
      positions.max(by: { $0.gap < $1.gap })?.position
    } else {
      // If the rectangles are diagonally separated, prefer their closest pair of edges.
      separatedPositions.min(by: { $0.gap < $1.gap })?.position
    }

    if let position {
      let triangles: [(DisplayPoint, DisplayPoint, DisplayPoint)] = switch position {
      case .left:
        [
          (DisplayPoint(x: anchorRect.maxX, y: anchorRect.maxY),
            DisplayPoint(x: windowRect.maxX, y: anchorRect.maxY),
            DisplayPoint(x: windowRect.maxX, y: windowRect.maxY)),
          (DisplayPoint(x: anchorRect.maxX, y: anchorRect.minY),
            DisplayPoint(x: windowRect.maxX, y: anchorRect.minY),
            DisplayPoint(x: windowRect.maxX, y: windowRect.minY)),
        ]
      case .right:
        [
          (DisplayPoint(x: anchorRect.minX, y: anchorRect.maxY),
            DisplayPoint(x: windowRect.minX, y: anchorRect.maxY),
            DisplayPoint(x: windowRect.minX, y: windowRect.maxY)),
          (DisplayPoint(x: anchorRect.minX, y: anchorRect.minY),
            DisplayPoint(x: windowRect.minX, y: anchorRect.minY),
            DisplayPoint(x: windowRect.minX, y: windowRect.minY)),
        ]
      case .above:
        [
          (DisplayPoint(x: anchorRect.minX, y: anchorRect.maxY),
            DisplayPoint(x: anchorRect.minX, y: windowRect.maxY),
            DisplayPoint(x: windowRect.minX, y: windowRect.maxY)),
          (DisplayPoint(x: anchorRect.maxX, y: anchorRect.maxY),
            DisplayPoint(x: anchorRect.maxX, y: windowRect.maxY),
            DisplayPoint(x: windowRect.maxX, y: windowRect.maxY)),
        ]
      case .below:
        [
          (DisplayPoint(x: anchorRect.minX, y: anchorRect.minY),
            DisplayPoint(x: anchorRect.minX, y: windowRect.minY),
            DisplayPoint(x: windowRect.minX, y: windowRect.minY)),
          (DisplayPoint(x: anchorRect.maxX, y: anchorRect.minY),
            DisplayPoint(x: anchorRect.maxX, y: windowRect.minY),
            DisplayPoint(x: windowRect.maxX, y: windowRect.minY)),
        ]
      }

      if triangles.contains(where: {
        locationOnScreen.isInsideTriangleWithVertices($0.0, $0.1, $0.2)
      }) {
        return .transientZone
      }
    }

    return nil
  }

  func isMovingTowardPopoverWindow(locationOnScreen: DisplayPoint) -> Bool {
    // Just assume so if we are just starting out.
    guard let lastLocationOnScreen = state.lastLocationOnScreen else {
      return true
    }

    // There should be a popover window.
    guard let windowRect else {
      return false
    }

    let lastDistance = lastLocationOnScreen.distance(to: windowRect.center)
    let newDistance = locationOnScreen.distance(to: windowRect.center)

    // Use 1 here instead of 0 to require more deliberate motion toward the popover window.
    return (lastDistance - newDistance) > 1
  }
}
