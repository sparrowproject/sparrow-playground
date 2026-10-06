extension View {
  public func contextPopover<PopoverContent: View>(
    style: @autoclosure @MainActor @escaping () -> PopoverStyle = .init(),
    content: @MainActor @escaping (PopoverController) -> PopoverContent,
  ) -> some View {
    modifier(_ContextPopoverModifier(
      style: style,
      popoverContent: content,
    ))
  }

  public func contextPopover<PopoverContent: View>(
    style: @autoclosure @MainActor @escaping () -> PopoverStyle = .init(),
    content: @MainActor @escaping () -> PopoverContent,
  ) -> some View {
    modifier(_ContextPopoverModifier(
      style: style,
      popoverContent: { _ in content() },
    ))
  }
}

@MainActor
struct _ContextPopoverModifier<PopoverContent: View> {
  let style: @MainActor () -> PopoverStyle
  let popoverContent: @MainActor (PopoverController) -> PopoverContent

  @State var isPresented = false
  @State var point = UnitPoint.zero
}

extension _ContextPopoverModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .onPointerDown { event in
        if event.isContextClick {
          point = event.location.unitPoint(in: .view)
          isPresented = true
        }
      }
      .modifier(
        _PopoverModifier(
          isPresented: $isPresented,
          preferredAnchor: { .anchorTo(.point(point), place: .below(alignment: .leading)) },
          style: style,
          content: { popoverContent(self) },
        )
      )
  }
}

extension _ContextPopoverModifier: PopoverController {
  public func dismiss() {
    isPresented = false
  }
}

extension PointerEvent {
  fileprivate var isContextClick: Bool {
    if buttons == .right {
      return true
    }
    
    #if os(macOS)
    if buttons == .left, modifierFlags.contains(.control) {
      return true
    }
    #endif

    return false
  }
}