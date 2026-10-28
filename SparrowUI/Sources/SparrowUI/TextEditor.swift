import Foundation
import SparrowUICore
import SparrowUIFoundation

/// A single line text editor.
public struct TextEditor: View {
  public enum Action {
    case submit
    case cancel
    case focusNext
    case focusPrevious
    case moveUp
    case moveDown

    /// Sent immediately after `text` changes due to user input. The receiver may
    /// alter `text` or `selection`, and the result will be applied immediately.
    /// Not sent due to programmatic update to `text`.
    case textChanged
  }

  public init(
    text: Binding<String>,
    selection: Binding<Range<String.Index>>? = nil,
    action: (@MainActor (Action) -> ())? = nil,
  ) {
    let selectionDefault = ObservableValue<Range<String.Index>>(
      text.get().endIndex ..< text.get().endIndex,
    )
    controller = .init(textBinding: text, selectionBinding: selection ?? .binding(for: \.value, of: selectionDefault))
    self.text = text
    self.selection = selection
    self.selectionDefault = selectionDefault
    config = .init(action: action)
  }

  public var body: some View {
    TextBoxRepresentable(controller: controller, action: config.action)
      .readColorScheme(to: $colorScheme)
      .onAppear {
        setText()
      }
      .onChange(of: (text.get(), selection?.get())) { _, _ in
        setText()
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
    selection: Binding<Range<String.Index>>?,
    selectionDefault: ObservableValue<Range<String.Index>>,
    config: Config,
  ) {
    self.controller = controller
    self.text = text
    self.selection = selection
    self.selectionDefault = selectionDefault
    self.config = config
  }

  private let controller: TextBoxRepresentable.Controller
  private let text: Binding<String>
  private let selection: Binding<Range<String.Index>>?
  private let selectionDefault: ObservableValue<Range<String.Index>>
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

  private func setText() {
    let text = text.get()
    if selection == nil {
      selectionDefault.value = text.endIndex ..< text.endIndex
    }
    controller.setText(text, withSelection: selection?.get() ?? selectionDefault.value)
  }
}

extension TextEditor {
  public func font(_ font: @autoclosure @MainActor @escaping () -> Font) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      selectionDefault: selectionDefault,
      config: with(config) { $0.font = font }
    )
  }

  public func foregroundColor(_ foregroundColor: @autoclosure @MainActor @escaping () -> Color) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      selectionDefault: selectionDefault,
      config: with(config) { $0.foregroundColor = foregroundColor }
    )
  }

  public func contentAlignment(_ contentAlignment: @autoclosure @MainActor @escaping () -> Alignment) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      selectionDefault: selectionDefault,
      config: with(config) { $0.contentAlignment = contentAlignment }
    )
  }

  public func contentPadding(_ contentPadding: @autoclosure @MainActor @escaping () -> EdgeInsets) -> TextEditor {
    .init(
      controller: controller,
      text: text,
      selection: selection,
      selectionDefault: selectionDefault,
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
      selectionDefault: selectionDefault,
      config: with(config) { $0.contentPadding = { .init(edges: edges(), value: value()) } }
    )
  }
}