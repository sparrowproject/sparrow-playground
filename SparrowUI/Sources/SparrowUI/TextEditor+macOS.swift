#if os(macOS)
import AppKit
import SparrowUICore
import SparrowUIFoundation

struct TextBoxRepresentable: NSViewRepresentable {
  init(controller: Controller, action: (@MainActor (TextEditor.Action) -> Void)?) {
    self.controller = controller
    self.action = action
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
    weak var context: CoreViewContext?
    weak var associatedView: CoreView?
    weak var editorView: TextEditorView?

    func setText(_ text: String, withSelection selection: Range<String.Index>) {
      guard let editorView else { return }

      assert(text == textBinding.get())
      assert(selection == selectionBinding.get())

      // Avoid interim updates.
      editorView.textChanged = nil
      editorView.selectionChanged = nil

      editorView.textView.string = text

      let range = NSRange(selection, in: text)
      editorView.textView.setSelectedRange(range)

      editorView.textChanged = textChanged
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

    func textChanged(_ value: String) {
      guard value != textBinding.get() else { return }
      
      textBinding.set(value)

      if let action = editorView?.action {
        action(.textChanged)
        setText(textBinding.get(), withSelection: selectionBinding.get())
      }
    }

    func selectionChanged(_ selection: Range<String.Index>) {
      selectionBinding.set(selection)
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
  var selectionChanged: (@MainActor (Range<String.Index>) -> Void)?

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
    selectionChanged?(Range(textView.selectedRange(), in: textView.string)!)
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
}

final class CustomTextView: NSTextView {
  var gotFocus: (@MainActor () -> Void)?
  var lostFocus: (@MainActor () -> Void)?

  override func becomeFirstResponder() -> Bool {
    let result = super.becomeFirstResponder()
    if result {
      gotFocus?()
    }
    return result
  }

  override func resignFirstResponder() -> Bool {
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

#endif