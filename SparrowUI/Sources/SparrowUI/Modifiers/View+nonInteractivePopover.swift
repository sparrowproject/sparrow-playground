extension View {
  public func nonInteractivePopover<Content: View>(
    isPresented: Binding<Bool>,
    preferredAnchor: @autoclosure @MainActor @escaping () -> PositionalAnchor,
    style: @autoclosure @MainActor @escaping () -> PopoverStyle = .init(),
    content: @MainActor @escaping () -> Content,
  ) -> some View {
    // TODO: Implement me!
    modifier(_PopoverModifier(
      isPresented: isPresented,
      preferredAnchor: preferredAnchor,
      style: style,
      content: content,
    ))
  }
}
