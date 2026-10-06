import Foundation
import SparrowUI

public struct SidebarResizer: View {
  public init(
    tracking: Binding<Bool>,
    onDelta: @escaping @MainActor (CGFloat) -> Void,
  ) {
    self._tracking = tracking
    self.onDelta = onDelta
  }

  public var body: some View {
    Rectangle()
      .fill(fillColor)
      .width(Metrics.width)
      .cursor(.resizeLeftRight)
      .onPointerEntered {
        withAnimation {
          isHovered = true
        }
      }
      .onPointerExited {
        withAnimation {
          isHovered = false
        }
      }
      .onPointerDown {
        $0.handled = true
        tracking = true
      }
      .onPointerUp {
        tracking = false
      }
      .onPointerDragged {
        onDelta($0.delta.x)
      }
  }

  private enum Metrics {
    static let width: CGFloat = 6
  }

  private let onDelta: @MainActor (CGFloat) -> Void

  private var fillColor: Color {
    isHovered ? Color.black.opacity(0.1) : .clear
  }

  @Binding private var tracking: Bool
  @State private var isHovered = false
}