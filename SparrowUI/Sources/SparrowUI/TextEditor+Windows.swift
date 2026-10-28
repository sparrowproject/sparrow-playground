#if os(Windows)
import Foundation
import SparrowUICore
import SparrowUIFoundation
import UWP
import WinAppSDK
import WinUI

final class TextBoxRepresentable: WinUIElementRepresentable {
  init(controller: Controller, action: (@MainActor (TextEditor.Action) -> Void)?) {
    self.controller = controller
    self.action = action

    controller.action = action
  }

  @MainActor
  final class Controller {
    init(
      textBinding: Binding<String>,
      selectionBinding: Binding<Range<String.Index>>,
    ) {
      self.textBinding = textBinding
      self.selectionBinding = selectionBinding
    }

    let textBinding: Binding<String>
    let selectionBinding: Binding<Range<String.Index>>
    let foregroundBrush = SolidColorBrush()
    var contentAlignment: Alignment = .leading
    var contentPadding: EdgeInsets = .zero
    weak var context: CoreViewContext?
    weak var associatedView: CoreView?
    var textBox: TextBox?
    var ignoreTextBoxEvents = false
    var action: (@MainActor (TextEditor.Action) -> Void)?

    func setText(_ text: String, withSelection selection: Range<String.Index>) {
      guard let textBox else { return }

      assert(text == textBinding.get())
      assert(selection == selectionBinding.get())

      ignoreTextBoxEvents = true
      defer { ignoreTextBoxEvents = false }

      if text != textBox.text {
        textBox.text = text
      }

      // Avoid re-setting selection if not changed as this can confuse the underlying TextBox,
      // interfering with shift-arrow interactive selection.

      let range = NSRange(selection, in: text) 
      let selectionStart = Int32(range.location) 
      let selectionLength = Int32(range.length)
      if textBox.selectionStart != selectionStart || textBox.selectionLength != selectionLength {
        try! textBox.select(selectionStart, selectionLength)
      }
    }

    func setFont(_ font: Font) {
      guard let textBox else { return }
      textBox.fontFamily = .init(font.family)
      textBox.fontSize = font.size
      textBox.fontWeight = .init(weight: UInt16(font.weight.value))
    }

    func setForegroundColor(_ foregroundColor: CoreColor) {
      foregroundBrush.color = foregroundColor.value
    }

    func setContentAlignment(_ alignment: Alignment) {
      contentAlignment = alignment
      updateLayout()
    }

    func setContentPadding(_ padding: EdgeInsets) {
      contentPadding = padding
      updateLayout()
    }

    func setFocused() {
      guard let textBox else { return }
      _ = try! textBox.focus(.programmatic)
    }

    func updateLayout() {
      guard let textBox else { return }

      let actualHeight = textBox.actualHeight
      guard actualHeight != 0 else { return }

      if contentAlignment != .leading {
        print(">>> TODO: missing implementation of TextBox.contentAlignment: \(contentAlignment)")
      }

      let textBlock = TextBlock()
      textBlock.text = "Ag"
      textBlock.fontFamily = textBox.fontFamily
      textBlock.fontSize = textBox.fontSize
      textBlock.fontWeight = textBox.fontWeight

      try! textBlock.measure(.init(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))

      let textHeight = CGFloat(textBlock.desiredSize.height)

      let availableHeight = textBox.actualHeight
        - contentPadding.top
        - contentPadding.bottom
        - textHeight

      textBox.padding = Thickness(
        left: contentPadding.leading,
        top: contentPadding.top + availableHeight / 2,
        right: contentPadding.trailing,
        bottom: contentPadding.bottom,
      )
    }

    func textChanging(_ value: String, withSelection selection: Range<String.Index>) {
      guard !ignoreTextBoxEvents else { return }

      var changed = false

      if textBinding.get() != value {
        textBinding.set(value)
        changed = true
      }
      if selectionBinding.get() != selection {
        selectionBinding.set(selection)
        changed = true
      }

      if changed {
        notifyTextChanged()
      }
    }

    func selectionChanged(_ selection: Range<String.Index>) {
      guard !ignoreTextBoxEvents else { return }

      if selectionBinding.get() != selection {
        selectionBinding.set(selection)
      }
    }

    private func notifyTextChanged() {
      guard let action else { return }

      action(.textChanged)

      setText(textBinding.get(), withSelection: selectionBinding.get())
    }
  }

  func makeUIElement(context: CoreViewContext, associatedView: CoreView) -> UIElement {
    let textBox = CustomTextBox()
    textBox.action = action

    controller.textBox = textBox
    controller.context = context
    controller.associatedView = associatedView

    associatedView.acceptsFocus = { true }

    textBox.placeholderText = ""
    textBox.textWrapping = .noWrap
    textBox.fontSize = 14
    textBox.borderThickness = Thickness()
    textBox.padding = Thickness()
    textBox.minHeight = 0
    textBox.isSpellCheckEnabled = false

    let clearBrush = SolidColorBrush(Colors.transparent)
    textBox.resources["TextControlBorderBrush"] = clearBrush
    textBox.resources["TextControlBorderBrushPointerOver"] = clearBrush
    textBox.resources["TextControlBorderBrushFocused"] = clearBrush
    textBox.resources["TextControlBackground"] = clearBrush
    textBox.resources["TextControlBackgroundPointerOver"] = clearBrush
    textBox.resources["TextControlBackgroundFocused"] = clearBrush

    textBox.foreground = controller.foregroundBrush
    textBox.resources["TextControlForeground"] = controller.foregroundBrush
    textBox.resources["TextControlForegroundFocused"] = controller.foregroundBrush
    textBox.resources["TextControlForegroundPointerOver"] = controller.foregroundBrush

    textBox.sizeChanged.addHandler { [controller] (_, event: SizeChangedEventArgs!) in
      guard event.newSize.height != event.previousSize.height else { return }
      controller.updateLayout()
    }

    textBox.textChanging.addHandler { [controller] _, _ in
      guard let textBox = controller.textBox else { return }
      // New value is already set on `TextBox.text`. It just hasn't been rendered yet.
      let text = textBox.text
      let selection = makeClampedRange(start: textBox.selectionStart, length: textBox.selectionLength, in: text)
      controller.textChanging(text, withSelection: selection)
    }

    textBox.selectionChanged.addHandler { [controller] _, _ in
      guard let textBox = controller.textBox else { return }
      let selection = makeClampedRange(start: textBox.selectionStart, length: textBox.selectionLength, in: textBox.text)
      controller.selectionChanged(selection)
    }

    textBox.gotFocus.addHandler { [controller] _, _ in
      guard
        let context = controller.context,
        let associatedView = controller.associatedView
      else { return }
      context.focusedView = associatedView
    }

    textBox.lostFocus.addHandler { [controller] _, _ in
      guard
        let context = controller.context,
        let associatedView = controller.associatedView
      else { return }
      if context.focusedView === associatedView {
        context.focusedView = nil
      }
    }

    return textBox
  }

  static func tearDownUIElement(_: UIElement) {}

  private let controller: Controller
  private let action: (@MainActor (TextEditor.Action) -> Void)?
}

private final class CustomTextBox: TextBox {
  var action: ((TextEditor.Action) -> Void)?

  /// This override is needed in order to get first shot at all events.
  /// The `keyDown` event handler does not see a down arrow press for
  /// example when text is selected.
  override func onKeyDown(_ event: KeyRoutedEventArgs!) throws {
    switch event.key {
    case .enter:
      action?(.submit)

    case .escape:
      action?(.cancel)
    
    case .up:
      action?(.moveUp)

    case .down:
      action?(.moveDown)

    default:
      try super.onKeyDown(event)
      return
    }

    event.handled = true
  }
}

fileprivate func makeClampedRange(start: Int32, length: Int32, in string: String) -> Range<String.Index> {
  let start = clamp(start, 0, Int32(string.count))
  let length = clamp(length, 0, Int32(string.count) - start)
  let range = NSRange(location: Int(start), length: Int(length))
  return .init(range, in: string)!
}

#endif