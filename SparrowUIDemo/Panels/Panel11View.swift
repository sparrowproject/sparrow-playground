import Foundation
import SparrowUI
import SparrowUIFoundation

struct Panel11View: PanelView {
  var body: some View {
    Group {
      backgroundColor

      // These should all look equivalent.

      Group {
        // Simple view with a simple view mask applied.
        TestElement()
          .height(40)
          .mask(simpleMask)

        // View tree with a simple view mask applied.
        Group {
          TestElement()
        }
        .height(40)
        .mask(simpleMask)
        .offset(y: 80)

        // Simple view with a view tree mask applied.
        TestElement()
          .height(40)
          .mask(complexMask)
          .offset(y: 160)

        // View tree with a view tree mask applied.
        Group {
          TestElement()
        }
        .height(40)
        .mask(complexMask)
        .offset(y: 240)
      }
      .padding(.vertical, 40)
      .padding(.leading, 40)
      .padding(.trailing, expand ? 40 : 80)
    }
    .onPointerDown {
      withAnimation {
        expand = true
      }
    }
    .onPointerUp {
      withAnimation {
        expand = false
      }
    }
  }

  @State private var expand = false

  private var backgroundColor: Color {
    .init(light: .init(gray: 0.9), dark: .init(gray: 0.1))
  }

  private var simpleMask: some View {
    LinearGradient(
      stops: [
        .init(color: .black, location: 0),
        .init(color: .clear, location: 1),
      ],
      startPoint: .leading,
      endPoint: .trailing,
    )
  }

  private var complexMask: some View {
    Group {
      LinearGradient(
        stops: [
          .init(color: .black, location: 0),
          .init(color: .clear, location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing,
      )
    }
  }
}

struct TestElement: View {
  var body: some View {
    Color.pink
      .opacity(isHovering ? 1 : 0.5)
      .onPointerEntered {
        withAnimation {
          isHovering = true
        }
      }
      .onPointerExited {
        withAnimation {
          isHovering = false
        }
      }
  }

  @State private var isHovering = false
}