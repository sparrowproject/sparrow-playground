import Foundation
import SparrowUI

#if os(macOS)
import AppKit
#elseif os(Windows)
import WinUI
#endif

struct Panel5View: PanelView {
  var body: some View {
    Group { geom in
      Rectangle()
        .fill(Color(.init(gray: 0.9)))

      RoundedRectangle(cornerRadius: 20)
        .fill(Color.green.opacity(0.4))
        .width(geom.width - 40)
        .height(geom.height - 40)
        .alignment(.center)

      RoundedRectangle(cornerRadius: 10)
        .fill(Color.white)
        .width(geom.width - 60)
        .height(geom.height - 60)
        .alignment(.center)

      textComparisonStack
    }
  }

  var textComparisonStack: some View {
    Group {
      Text("Hello, world!")
        .font(.system(size: 14))
        .alignment(.topLeading)
        .padding(.top, 60)
        .offset(x: 100)
      #if os(macOS)
      TextFieldRepresentable(text: "Hello, world!")
        .alignment(.topLeading)
        .padding(.top, 80)
        .offset(x: 100)
      #elseif os(Windows)
      TextBlockRepresentable(text: "Hello, world!")
        .alignment(.topLeading)
        .padding(.top, 80)
        .offset(x: 100)
      #endif
    }
  }
}

#if os(macOS)
private struct TextFieldRepresentable: NSViewRepresentable {
  let text: String

  func makeNSView() -> NSTextField {
    let textField = NSTextField()
    textField.cell = PaddinglessTextFieldCell()
    textField.font = NSFont.systemFont(ofSize: 14)
    textField.alignment = .left
    textField.isBordered = false
    textField.drawsBackground = false
    textField.isEditable = false
    textField.isSelectable = false

    textField.stringValue = text
    textField.textColor = .black

    return textField
  }

  static func tearDownNSView(_: NSTextField) {}
}
private final class PaddinglessTextFieldCell: NSTextFieldCell {
  override func drawingRect(forBounds rect: NSRect) -> NSRect {
    // Remove some internal padding.
    .init(x: rect.minX - 2, y: rect.minY - 2, width: rect.width, height: rect.height)
  }
}
#elseif os(Windows)
private struct TextBlockRepresentable: WinUIElementRepresentable {
  let text: String

  func makeUIElement() -> TextBlock {
    let textBlock = TextBlock()
    textBlock.text = text
    textBlock.fontFamily = .init("Segoe UI")
    textBlock.fontSize = 14
    textBlock.fontWeight = .init(weight: 400)
    return textBlock
  }

  static func tearDownUIElement(_: TextBlock) {}
}
#endif