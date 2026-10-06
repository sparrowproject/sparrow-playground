import Foundation
import SparrowUI

struct Panel6View: PanelView {
  var body: some View {
    Group { geom in
      Rectangle()
        .fill(Color(.init(gray: 0.9)))

      editorPanel(.first)
        .offset(y: 100)

      editorPanel(.second)
        .offset(y: 140)

      Group {
        focusButton(.first)
          .offset(x: 40)
        focusButton(.second)
          .offset(x: 148)
      }
      .offset(y: 180)
    }
    .onChange(of: focusedField) { field in
      if let field {
        print(">>> focusedField value changed to: \(field)")
      } else {
        print(">>> focusedField value changed to: nil")
      }
    }
  }

  private enum Field {
    case first
    case second
  }

  @State private var focusedField: Field?

  private func editorPanel(_ field: Field) -> some View {
    Group {
      RoundedRectangle(cornerRadius: 7)
        .fill(.white)

      TextEditor(text: .init(get: { "\(field)" }, set: { _ in }))
        .font(.system(size: 14))
        .padding(.horizontal, 7)
        .alignment(.center)
        .focused(when: $focusedField, equals: field)
    }
    .height(32)
    .padding(.horizontal, 40)
  }

  private func focusButton(_ field: Field) -> some View {
    Button(action: {
      focusedField = field
    }, label: { config in
      Group {
        RoundedRectangle(cornerRadius: 6)
          .fill(buttonBackground(for: config))
        Text("Focus \(field)")
          .alignment(.center)
      }
      .opacity(buttonOpacity(for: config))
    })
    .width(100)
    .height(32)
  }

  private func buttonBackground(for config: ButtonConfig) -> Color {
    .black.opacity(0.1)
  }

  private func buttonOpacity(for config: ButtonConfig) -> CGFloat {
    if config.isPressed {
      0.6
    } else if config.isHovered {
      1
    } else {
      0.8
    }
  }

}
