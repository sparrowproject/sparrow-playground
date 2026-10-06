import Foundation
import SparrowCommands
import SparrowDesignSystem
import SparrowUI

public struct TabView: View {
  public enum Action {
    case select
    case close
    case command(SparrowCommand.ID)
  }

  public struct Options: OptionSet, Sendable {
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    public let rawValue: Int

    public static let noCloseButton = Options(rawValue: 1 << 0)
  }

  enum Metrics {
    static let intraContentPadding: CGFloat = 8
    static let closeButtonSize: CGFloat = 14

    static let iconSize: CGFloat = StandardMetrics.iconSize
    static let titleFont = Font.system(size: 13, weight: .light)

    static let dragThreshold: CGFloat = 5
  }

  init(
    viewModel: TabViewModel,
    contentAlignment: @autoclosure @escaping () -> Alignment,
    contentInsets: @autoclosure @escaping () -> EdgeInsets,
    intendedSize: @autoclosure @escaping () -> CGSize,
    options: @autoclosure @escaping () -> Options = [],
    action: @escaping (Action) -> Void,
  ) {
    self.viewModel = viewModel
    self.contentAlignment = contentAlignment
    self.contentInsets = contentInsets
    self.intendedSize = intendedSize
    self.options = options
    self.action = action
  }

  public var body: some View {
    Group { geom in
      Group {
        content
          .padding(.leading, Metrics.intraContentPadding + contentInsets().leading)
          .padding(.trailing, Metrics.intraContentPadding + contentInsets().trailing)
          .padding(.top, contentInsets().top)
          .padding(.bottom, contentInsets().bottom)
      }
      .width(intendedSize().width)
      .height(intendedSize().height)
      .alignment(contentAlignment()) // .leading)
    }
    .clipped()
    .onAppear {
      viewModel.isExpanded = true
    }
    .onPointerDown { event in
      guard event.buttons == .left else { return }
      pointerDownAt = event.location.point(in: .view)
      event.handled = true
      if !viewModel.isSelected {
        action(.select)
      }
    }
    .onPointerDragged { event in
      // Avoid recognizing a drag until some threshold is overcome.
      if
        !viewModel.isDragging,
        let pointerDownAt,
        pointerDownAt.distance(to: event.location.point(in: .view)) < Metrics.dragThreshold
      {
        return
      }
      viewModel.dragOffset = .init(
        x: (viewModel.dragOffset?.x ?? 0) + event.delta.x,
        y: (viewModel.dragOffset?.y ?? 0) + event.delta.y,
      )
    }
    .onPointerUp {
      withAnimation {
        pointerDownAt = nil
        viewModel.dragOffset = nil
      }
    }
    .onPointerEntered { event in
      viewModel.isHovered = true
    }
    .onPointerExited { event in
      viewModel.isHovered = false
    }
    .contextPopover() { controller in
      TabContextMenuView(tabsStyle: viewModel.style, isEnabled: viewModel.isCommandEnabled) {
        controller.dismiss()
        action(.command($0))
      }
    }
  }

  private let viewModel: TabViewModel
  private let contentAlignment: () -> Alignment
  private let contentInsets: () -> EdgeInsets
  private let intendedSize: () -> CGSize
  private let options: () -> Options
  private let action: (Action) -> Void

  @State private var pointerDownAt: CGPoint?

  private var content: some View {
    Group { geom in
      icon
        .alignment(.leading)
      title
        .offset(x: Metrics.iconSize + Metrics.intraContentPadding)
        .width(titleWidth(geom: geom))
      closeButton
        .alignment(.trailing)
        .visible(closeButtonIsVisible(geom: geom))
    }
    .clipped()
  }

  private var icon: some View {
    Image(source: viewModel.icon ?? StandardImages.defaultFavicon)
      .resizable()
      .tintColor(viewModel.icon == nil ? .primaryText.opacity(0.4) : nil)
      .width(Metrics.iconSize)
      .height(Metrics.iconSize)
  }

  private var title: some View {
    Text(viewModel.titleText)
      .font(Metrics.titleFont)
      .foregroundColor(.primaryText)
      .elideWithGradientMask()
  }

  private var closeButton: some View {
    Button {
      action(.close)
    } label: { _ in
      Symbol(source: closeButtonSymbol)
        .tintColor(.primaryText)
    }
    .buttonStyle(.standard)
    .width(Metrics.closeButtonSize)
    .height(Metrics.closeButtonSize)
  }

  private var closeButtonSymbol: SymbolSource {
    #if os(macOS)
    .init(systemName: "multiply", size: 9)
    #elseif os(Windows)
    .init(glyph: "\u{e711}", size: 9) // Cancel
    #endif
  }

  private func titleWidth(geom: GeometryProxy) -> CGFloat {
    let baseWidth = geom.width - Metrics.iconSize - Metrics.intraContentPadding
    return if !options().contains(.noCloseButton), viewModel.isHovered {
      baseWidth - Metrics.closeButtonSize - Metrics.intraContentPadding
    } else {
      baseWidth
    }
  }

  private func closeButtonIsVisible(geom: GeometryProxy) -> Bool {
    !options().contains(.noCloseButton)
      && viewModel.isHovered
      && (geom.width > Metrics.iconSize + Metrics.intraContentPadding + Metrics.closeButtonSize)
  }
}