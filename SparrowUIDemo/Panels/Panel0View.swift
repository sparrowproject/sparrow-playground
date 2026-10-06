import Foundation
import SparrowUI

#if os(macOS)
import CoreGraphics
#endif

struct Panel0View: PanelView {
  var body: some View {
    Group { geom in
      backgroundColor

      Color.blue
        .offset(x: 40, y: 40)
        .width(200)
        .height(200)
        .opacity(pressed ? 0.3 : (hovered ? 0.5 : 0.7))
        .scaleEffect(pressed ? 1.05 : 1)
        .onPointerDown {
          withAnimation {
            pressed = true
          }
        }
        .onPointerUp {
          withAnimation {
            pressed = false
          }
        }
        .onPointerEntered {
          withAnimation {
            hovered = true
          }
        }
        .onPointerExited {
          withAnimation {
            hovered = false
          }
        }

      RoundedRectangle(cornerRadius: pressed ? 40 : 0)
        .fill(.purple)
        .stroke(.black.opacity(pressed ? 0.1 : 0))
        .offset(x: 280, y: 40)
        .width(dynamicColorElementWidth(for: geom))
        .height(200)
        .shadow(color: .black.opacity(0.4), radius: 12, x: 2, y: 2)

      Color(pressed ? .yellow : .orange)
        .offset(x: 40, y: 280)
        .width(pressed ? 400 : 300)
        .height(100)
        .readSize(to: .init(get: { .zero }, set: { print(">>> new size is: \($0)") }))

      Group {
        Color.green
        Text("Hello!")
          .foregroundColor(.blue)
          .readSize(to: $textSize)
      }
      .offset(x: pressed ? 450 : 350, y: 280)
      .width(textSize.width)
      .height(textSize.height)

      Repeated(0..<numTiles, id: \.self) { index in
        tile(atIndex: index)
          .width(40)
          .height(100)
          .offset(x: CGFloat(index) * 42)
      }
      .offset(x: 40, y: 420)
      .width(260)
      .height(100)
      .clipped()

      Color.black
        .opacity(0.3)
        .width(200)
        .height(200)
        .offset(x: geom.width - 240, y: geom.height - 240)
    }
  }

  @State private var pressed = false
  @State private var hovered = false
  @State private var textSize = CGSize.zero

  private var numTiles: Int {
    pressed ? 10 : 4
  }

  private func dynamicColorElementWidth(for geom: GeometryProxy) -> CGFloat {
    max(50, geom.width - 3 * 40 - 200)
  }

  private var backgroundColor: Color {
    .init(light: .init(gray: 0.9), dark: .init(gray: 0.1))
  }

  private func tile(atIndex index: Int) -> some View {
    Group {
      Group { // Extra nesting to suss out a bug.
        RoundedRectangle(cornerRadius: 5)
          .fill(.init(.init(gray: 0.4 + 0.05 * CGFloat(index))))
        Color.white
          .opacity(0.2)
          .padding(.all, 10)
      }
    }
  }
}
