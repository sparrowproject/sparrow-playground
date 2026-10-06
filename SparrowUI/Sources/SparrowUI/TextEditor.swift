import Foundation
import SparrowUICore
import SparrowUIFoundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import UWP
import WinAppSDK
import WinUI
#endif

/// A single line text editor.
public struct TextEditor: View {
  public enum Action {
    case submit
    case cancel
    case focusNext
    case focusPrevious
    case moveUp
    case moveDown
  }

  public init(
    text: Binding<String>,
    selection: Binding<Range<String.Index>?>? = nil,
    action: (@MainActor (Action) -> ())? = nil,
  ) {
    controller = .init(textChanged: { text.set($0) }, selectionChanged: { selection?.set($0) })
    self.text = text
    self.selection = selection
    config = .init(action: action)
  }

  public var body: some View {
    TextBoxRepresentable(controller: controller, action: config.action)
      .readColorScheme(to: $colorScheme)
      .onChange(of: (text.get(), selection?.get())) {
        controller.setText($0.0, withSelection: $0.1)
      }
      .onChange(of: config.font()) {
        controller.setFont($0)
      }
      .onChange(of: foregroundCoreColor) {
        controller.setForegroundColor($0)
      }
      .onChange(of: config.contentAlignment()) {
        controller.setContentAlignment($0)
      }
      .onChange(of: config.contentPadding()) {
        controller.setContentPadding($0)
      }
      .onChange(of: shouldFocus) {
        if $0 {
          controller.setFocused()
        }
      }
  }

  private struct Config {
    var action: (@MainActor (TextEditor.Action) -> Void)?
    var font: (@MainActor () -> Font) = { .default }
    var foregroundColor: (@MainActor () -> Color) = { .primaryText }
    var contentAlignment: (@MainActor () -> Alignment) = { .topLeading }
    var contentPadding: (@MainActor () -> EdgeInsets) = { .zero }
  }

  private init(
    controller: TextBoxRepresentable.Controller,
    text: Binding<String>,
    selection: Binding<Range<String.Index>?>?,
    config: Config,
  ) {
    self.controller = controller
    self.text = text
    self.selection = selection
    self.config = config
  }

  private let controller: TextBoxRepresentable.Controller
  private let text: Binding<String>
  private let selection: Binding<Range<String.Index>?>?
  private let config: Config
  @State private var colorScheme = ColorScheme.light

  private var displayedText: String {
    let text = text.get()
    return text.isEmpty ? " " : text
  }

  private var foregroundCoreColor: CoreColor {
    config.foregroundColor().resolved(with: colorScheme)
  }

  private var shouldFocus: Bool {
    guard
      let context = controller.context,
      let associatedView = controller.associatedView
    else { return false }
    return context.focusedView === associatedView
  }
}

extension TextEditor {
  public func font(_ font: @autoclosure @MainActor @escaping () -> Font) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      config: with(config) { $0.font = font }
    )
  }

  public func foregroundColor(_ foregroundColor: @autoclosure @MainActor @escaping () -> Color) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      config: with(config) { $0.foregroundColor = foregroundColor }
    )
  }

  public func contentAlignment(_ contentAlignment: @autoclosure @MainActor @escaping () -> Alignment) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      config: with(config) { $0.contentAlignment = contentAlignment }
    )
  }

  public func contentPadding(_ contentPadding: @autoclosure @MainActor @escaping () -> EdgeInsets) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      config: with(config) { $0.contentPadding = contentPadding }
    )
  }

  public func contentPadding(
    _ edges: @autoclosure @MainActor @escaping () -> EdgeSet,
    _ value: @autoclosure @MainActor @escaping () -> CGFloat,
  ) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      config: with(config) { $0.contentPadding = { .init(edges: edges(), value: value()) } }
    )
  }
}

#if os(macOS)
private struct TextBoxRepresentable: NSViewRepresentable {
  init(controller: Controller, action: (@MainActor (TextEditor.Action) -> Void)?) {
    self.controller = controller
    self.action = action
  }

  @MainActor
  final class Controller {
    init(
      textChanged: @escaping @MainActor (String) -> Void,
      selectionChanged: @escaping @MainActor (Range<String.Index>?) -> Void,
    ) {
      self.textChanged = textChanged
      self.selectionChanged = selectionChanged
    }

    let textChanged: @MainActor (String) -> Void
    let selectionChanged: @MainActor (Range<String.Index>?) -> Void
    weak var context: CoreViewContext?
    weak var associatedView: CoreView?
    weak var editorView: TextEditorView?

    func setText(_ text: String, withSelection selection: Range<String.Index>?) {
      guard let editorView else { return }
      // Avoid interim updates to the selection.
      editorView.selectionChanged = nil
      editorView.textView.string = text
      let range =
        if let selection {
          NSRange(selection, in: text)
        } else {
          NSRange(location: editorView.textView.selectedRange().location, length: 0)
        }
      editorView.textView.setSelectedRange(range)
      editorView.selectionChanged = selectionChanged
    }

    func setFont(_ font: Font) {
      guard let editorView else { return }
      editorView.textView.font = NSFont.from(font)
    }

    func setForegroundColor(_ foregroundColor: CoreColor) {
      guard let editorView else { return }
      editorView.textView.textColor = .init(cgColor: foregroundColor.value)
    }

    func setContentAlignment(_ alignment: Alignment) {
      editorView?.contentAlignment = alignment
    }

    func setContentPadding(_ padding: EdgeInsets) {
      editorView?.contentPadding = padding
    }

    func setFocused() {
      guard let textView = editorView?.textView else { return }
      textView.window?.makeFirstResponder(textView)
    }
  }

  func makeNSView(context: CoreViewContext, associatedView: CoreView) -> TextEditorView {
    controller.context = context
    controller.associatedView = associatedView

    associatedView.acceptsFocus = { true }

    let editorView = TextEditorView()
    editorView.action = action
    editorView.textChanged = controller.textChanged
    editorView.selectionChanged = controller.selectionChanged
    controller.editorView = editorView

    editorView.textView.gotFocus = {
      guard
        let context = controller.context,
        let associatedView = controller.associatedView
      else { return }
      context.focusedView = associatedView
    }
    editorView.textView.lostFocus = {
      guard
        let context = controller.context,
        let associatedView = controller.associatedView
      else { return }
      if context.focusedView === associatedView {
        context.focusedView = nil
      }
    }

    return editorView
  }

  static func tearDownNSView(_: TextEditorView) {}

  private let controller: Controller
  private let action: (@MainActor (TextEditor.Action) -> Void)?
}

final class TextEditorView: NSView, NSTextViewDelegate {
  init() {
    super.init(frame: .zero)
    addSubview(scrollView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var action: (@MainActor (TextEditor.Action) -> Void)?
  var textChanged: (@MainActor (String) -> Void)?
  var selectionChanged: (@MainActor (Range<String.Index>?) -> Void)?

  var contentAlignment: Alignment = .topLeading {
    didSet {
      guard contentAlignment != oldValue else { return }
      needsLayout = true
    }
  }

  var contentPadding: EdgeInsets = .zero {
    didSet {
      guard contentPadding != oldValue else { return }
      needsLayout = true
    }
  }

  override func layout() {
    super.layout()

    guard
      let layoutManager = textView.layoutManager,
      let textContainer = textView.textContainer
    else { return }

    layoutManager.ensureLayout(for: textContainer)

    let usedRect = layoutManager.usedRect(for: textContainer)
    let textHeight = usedRect.height

    textView.maxSize = NSSize(
      width: .greatestFiniteMagnitude,
      height: textHeight,
    )
    textView.textContainer?.containerSize = .init(
      width: .greatestFiniteMagnitude,
      height: textHeight,
    )
    textView.textContainerInset = .init(
      width: 1, // For the cursor
      height: 0,
    )

    scrollView.frame = bounds.insetBy(dx: 7 - 1, dy: (bounds.height - textHeight) / 2)
  }

  override func mouseDown(with event: NSEvent) {
    // Forward mouse down events so that clicking outside of the text area but still
    // within this view acts as if the text area was clicked.
    textView.mouseDown(with: event)
  }

  func textView(
    _ textView: NSTextView,
    doCommandBy commandSelector: Selector
  ) -> Bool {
    switch commandSelector {
    case #selector(insertNewline(_:)),
         #selector(insertNewlineIgnoringFieldEditor(_:)):
      action?(.submit)
      return true

    case #selector(cancelOperation(_:)):
      action?(.cancel)
      return true

    case #selector(insertTab(_:)):
      action?(.focusNext)
      return true

    case #selector(insertBacktab(_:)):
      action?(.focusPrevious)
      return true

    case #selector(moveUp(_:)):
      action?(.moveUp)
      return true

    case #selector(moveDown(_:)):
      action?(.moveDown)
      return true

    default:
      return false
    }
  }

  func textDidChange(_: Notification) {
    textChanged?(textView.string)
  }

  func textViewDidChangeSelection(_: Notification) {
    _selectedRange = Range(textView.selectedRange(), in: textView.string)
  }

  private(set) lazy var scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.documentView = textView
    return scrollView
  }()

  private(set) lazy var textView: CustomTextView = {
    let textView = CustomTextView()
    textView.string = "Hello, world!"
    textView.isHorizontallyResizable = true
    textView.textContainer?.widthTracksTextView = false
    textView.textContainer?.lineFragmentPadding = 0
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.isAutomaticSpellingCorrectionEnabled = false
    textView.delegate = self
    return textView
  }()

  private var _selectedRange: Range<String.Index>? {
    didSet {
      guard _selectedRange != oldValue else { return }
      selectionChanged?(_selectedRange)
    }
  }
}

final class CustomTextView: NSTextView {
  var gotFocus: (@MainActor () -> Void)?
  var lostFocus: (@MainActor () -> Void)?

  override func becomeFirstResponder() -> Bool {
    print(">>> CustomTextView @\(ObjectIdentifier(self)) became first responder!")
    let result = super.becomeFirstResponder()
    if result {
      gotFocus?()
    }
    return result
  }

  override func resignFirstResponder() -> Bool {
    print(">>> CustomTextView @\(ObjectIdentifier(self)) resigned first responder!")
    let result = super.resignFirstResponder()
    if result {
      lostFocus?()
    }
    return result
  }

  override func paste(_ sender: Any?) {
    let pasteboard = NSPasteboard.general

    if let string = pasteboard.string(forType: .string) {
      let cleaned = string
        .replacingOccurrences(of: "\r\n", with: " ")
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
      insertText(cleaned, replacementRange: selectedRange())
    }
  }
}

#elseif os(Windows)
private final class TextBoxRepresentable: WinUIElementRepresentable {
  init(controller: Controller, action: (@MainActor (TextEditor.Action) -> Void)?) {
    self.controller = controller
    self.action = action
  }

  @MainActor
  final class Controller {
    init(
      textChanged: @escaping @MainActor (String) -> Void,
      selectionChanged: @escaping @MainActor (Range<String.Index>?) -> Void,
    ) {
      self.textChanged = textChanged
      self.selectionChanged = selectionChanged
    }

    let textChanged: @MainActor (String) -> Void
    let selectionChanged: @MainActor (Range<String.Index>?) -> Void
    let foregroundBrush = SolidColorBrush()
    var contentAlignment: Alignment = .leading
    var contentPadding: EdgeInsets = .zero
    weak var context: CoreViewContext?
    weak var associatedView: CoreView?
    var textBox: TextBox?

    var selection: Range<String.Index>? {
      didSet {
        guard selection != oldValue else { return }
        selectionChanged(selection)
      }
    }

    func setText(_ text: String, withSelection selection: Range<String.Index>?) {
      guard let textBox else { return }
      if text != textBox.text {
        textBox.text = text
      }
      // Avoid re-setting selection if not changed as this can confuse the underlying TextBox,
      // interfering with shift-arrow interactive selection.
      if selection != self.selection {
        if let selection {
          let range = NSRange(selection, in: text)
          textBox.selectionStart = Int32(range.location)
          textBox.selectionLength = Int32(range.length)
        } else {
          textBox.selectionLength = 0
        }
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

    textBox.textChanged.addHandler { [controller] _, _ in
      guard let textBox = controller.textBox else { return }
      controller.textChanged(textBox.text)
    }

    textBox.selectionChanged.addHandler { [controller] _, _ in
      guard let textBox = controller.textBox else { return }
      let range = NSRange(location: Int(textBox.selectionStart), length: Int(textBox.selectionLength))
      controller.selection = Range(range, in: textBox.text)
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