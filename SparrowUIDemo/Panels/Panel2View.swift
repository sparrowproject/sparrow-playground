import Foundation
import SparrowUI

#if os(macOS)
import CoreGraphics
#endif

struct Panel2View: PanelView {
  var body: some View {
    Group { geom in
      background

      content
        .offset(x: 20, y: 20)
        .width(200)
        .height(geom.height - 40)
        .readSize(to: $viewPortSize)
        .acceptsFocus()
        .focused(when: $focused, equals: true)
        .onPointerDown {
          print(">>> setting focused = true")
          focused = true
        }
        .onPointerWheel {
          // TODO: Add rubberbanding (or maybe best done by overlaying a NSScrollView).
          scrollOffset = clampedScrollOffset(scrollOffset - $0.delta.y)
        }
        .onChange(of: viewPortSize) { _ in
          scrollOffset = clampedScrollOffset(scrollOffset)
        }
        .onChange(of: selectedIndex) { _ in
          scrollOffset = computeScrollOffsetEnsuringSelectedIndexIsVisible()
        }
        .onKeyDown {
          #if os(macOS)
          switch $0.key.keyCode {
          case 125:
            selectedIndex = clampedSelectedIndex(selectedIndex + 1)
          case 126:
            selectedIndex = clampedSelectedIndex(selectedIndex - 1)
          default:
            break
          }
          #elseif os(Windows)
          switch $0.key.virtualKey {
          case .up:
            selectedIndex = clampedSelectedIndex(selectedIndex - 1)
          case .down:
            selectedIndex = clampedSelectedIndex(selectedIndex + 1)
          default:
            break
          }
          #endif
        }
    }
  }

  private enum Metrics {
    static let padding: CGFloat = 10
    static let rowHeight: CGFloat = 30
  }

  @State private var count = 100
  @State private var selectedIndex = 0
  @State private var scrollOffset = CGFloat.zero
  @State private var viewPortSize = CGSize.zero
  @State private var focused: Bool?

  private func computeScrollOffsetEnsuringSelectedIndexIsVisible() -> CGFloat {
    let visibleMinY = scrollOffset
    let visibleMaxY = scrollOffset + viewPortSize.height

    let visibleStartIndex = Int((visibleMinY - Metrics.padding) / Metrics.rowHeight)
    let visibleEndIndex = Int((visibleMaxY - Metrics.padding) / Metrics.rowHeight)

    return
      if selectedIndex <= visibleStartIndex {
        clampedScrollOffset(scrollOffset - Metrics.rowHeight)
      } else if selectedIndex >= visibleEndIndex {
        clampedScrollOffset(scrollOffset + Metrics.rowHeight)
      } else {
        scrollOffset
      }
  }

  private func clampedScrollOffset(_ scrollOffset: CGFloat) -> CGFloat {
    let maxScrollOffset = CGFloat(count) * Metrics.rowHeight + 2 * Metrics.padding - viewPortSize.height //+ 40
    return max(0, min(maxScrollOffset, scrollOffset))
  }

  private func clampedSelectedIndex(_ selectedIndex: Int) -> Int {
    max(0, min(count - 1, selectedIndex))
  }

  private var visibleIndices: Range<Int> {
    let visibleMinY = scrollOffset
    let visibleMaxY = scrollOffset + viewPortSize.height

    let visibleStartIndex = Int((visibleMinY - Metrics.padding) / Metrics.rowHeight)
    let visibleEndIndex = Int((visibleMaxY - Metrics.padding) / Metrics.rowHeight)

    let lowerBound = max(0, visibleStartIndex)
    let upperBound = min(count, visibleEndIndex + 1)
    return .init(uncheckedBounds: (lower: lowerBound, upper: upperBound))
  }

  private var background: some View {
    Color(.init(gray: 0.9))
  }

  private var content: some View {
    Group { geom in
      Color.white

      Repeated(visibleIndices, id: \.self) { index in
        row(for: index)
          .width(geom.width - 20)
          .height(30)
          .offset(x: Metrics.padding, y: Metrics.rowHeight * CGFloat(index) + Metrics.padding - scrollOffset)
      }
      .clipped()
    }
  }

  private func row(for index: Int) -> some View {
    Button {
      selectedIndex = index
    } label: { config in
      Group {
        Rectangle()
          .fill(rowBackgroundColor(atIndex: index, with: config))
        Text("Row \(index)")
          .font(.system(size: 14))
          .alignment(.leading)
          .padding(.horizontal, Metrics.padding)
      }
    }
  }

  private func rowBackgroundColor(atIndex index: Int, with config: ButtonConfig) -> Color {
    let opacity: CGFloat =
      if config.isPressed {
        0.15
      } else if config.isHovered {
        0.35
      } else if selectedIndex == index {
        0.25
      } else {
        0
      }
    return .cyan.opacity(opacity)
  }
}
