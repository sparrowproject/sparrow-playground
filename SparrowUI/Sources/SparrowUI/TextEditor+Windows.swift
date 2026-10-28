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

    controller.changed = { action?(.changed) }
  }

  @MainActor
  final class Controller {
    init(
      textBinding: Binding<String>,
      selectionBinding: Binding<Range<String.Index>?>,
    ) {
      self.textBinding = textBinding
      self.selectionBinding = selectionBinding
    }

    let textBinding: Binding<String>
    let selectionBinding: Binding<Range<String.Index>?>
    let foregroundBrush = SolidColorBrush()
    var contentAlignment: Alignment = .leading
    var contentPadding: EdgeInsets = .zero
    weak var context: CoreViewContext?
    weak var associatedView: CoreView?
    var textBox: TextBox?
    var ignoreTextBoxEvents = false
    var changed: (() -> Void)?

    // var selection: Range<String.Index>? {
    //   didSet {
    //     print(">>> didSet selection: \(selection), oldValue: \(oldValue)")
    //     guard selection != oldValue else { return }
    //     selectionChanged(selection)
    //   }
    // }

    func setText(_ text: String, withSelection selection: Range<String.Index>?) {
      guard let textBox else { return }

      assert(text == textBinding.get())
      assert(selection == selectionBinding.get())

      ignoreTextBoxEvents = true
      defer { ignoreTextBoxEvents = false }

      print(">>> setText: \"\(text)\", selection: \(selection), current: \"\(textBox.text)\", selection: \(textBox.selectionStart), \(textBox.selectionLength)")

      let existingSelectionStart = textBox.selectionStart

      if text != textBox.text {
        textBox.text = text
      }

      // Avoid re-setting selection if not changed as this can confuse the underlying TextBox,
      // interfering with shift-arrow interactive selection.

      let (selectionStart, selectionLength) =
        if let range = selection.flatMap({ NSRange($0, in: text) }) {
          (Int32(range.location), Int32(range.length))
        } else {
          (max(existingSelectionStart, Int32(text.count)), 0)
        }
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

    func textChanging(_ value: String, withSelection selection: Range<String.Index>?) {
      print(">>> textChanging: \(value), withSelection: \(selection)")

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
        notifyChanged()
      }

      // self.selection = selection
      // textBinding.set(value)

      // // If the text binding was modified, then reflect that change immediately to avoid flicker.
      // let valueAfter = textBinding.get()
      // if valueAfter != value {
      //   print(">>> calling setText w/ valueAfter: \"\(valueAfter)\"")
      //   setText(valueAfter, withSelection: selectionBinding.flatMap { $0.get() })
      // }
    }

    func selectionChanged(_ selection: Range<String.Index>?) {
      // guard let selectionBinding else { return }

      print(">>> selectionChanged: \(selection)")

      guard !ignoreTextBoxEvents else { return }

      // selectionBinding.set(selection)

      var changed = false

      if selectionBinding.get() != selection {
        selectionBinding.set(selection)
        changed = true
      }

      if changed {
        notifyChanged()
      }

      // // If the selection binding was modified, then reflect that change immediately to avoid flicker.
      // let selectionAfter = selectionBinding.get()
      // if selectionAfter != selection {
      //   print(">>> calling setText w/ selectionAfter: \"\(selectionAfter)\"")
      //   setText(textBinding.get(), withSelection: selectionAfter)
      // }
    }

    private func notifyChanged() {
      guard let textBox, let changed else { return }

      changed()

      setText(textBinding.get(), withSelection: selectionBinding.get())

      // ignoreTextBoxEvents = true
      // defer { ignoreTextBoxEvents = false }

      // if textBox.text != textBinding.get() {
      //   textBox.text = textBinding.get()
      // }
    }
  }

  func makeUIElement(context: CoreViewContext, associatedView: CoreView) -> UIElement {
    let textBox = TextBox()
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
      print(">>> textChanging to: \(textBox.text), selection: \(textBox.selectionStart), \(textBox.selectionLength)")
      // New value is already set on `TextBox.text`. It just hasn't been rendered yet.
      let text = textBox.text
      let range = NSRange(location: Int(textBox.selectionStart), length: Int(textBox.selectionLength))
      let selection = Range(range, in: text)
      controller.textChanging(text, withSelection: selection)
    }

    textBox.selectionChanged.addHandler { [controller] _, _ in // (_, args: TextBoxSelectionChangingEventArgs!) in
      guard let textBox = controller.textBox else { return }
      print(">>> selectionChanged to: \(textBox.selectionStart), \(textBox.selectionLength) for text: \"\(textBox.text)\"")
      // New values are given by `args`.
      let range = NSRange(location: Int(textBox.selectionStart), length: Int(textBox.selectionLength))
      controller.selectionChanged(Range(range, in: textBox.text))
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

    textBox.keyDown.addHandler { [action] (_, event: KeyRoutedEventArgs!) in
      switch event.key {
      case VirtualKey.enter:
        action?(.submit)

      case VirtualKey.escape:
        action?(.cancel)

      default:
        return
      }

      event.handled = true
    }

    return textBox
  }

  static func tearDownUIElement(_: UIElement) {}

  private let controller: Controller
  private let action: (@MainActor (TextEditor.Action) -> Void)?
}
#endif