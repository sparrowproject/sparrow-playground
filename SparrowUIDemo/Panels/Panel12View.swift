import SparrowUI

struct Panel12View: PanelView {
  var body: some View {
    Group {
      backgroundColor

      Group {
        showModalButton(for: $showModal1)
        showModalButton(for: $showModal2)
          .offset(x: 130, y: 50)
        showModalButton(for: $showModal3)
          .offset(x: 260, y: 100)
      }
      .width(380)
      .height(140)
      .alignment(.topLeading)
    }
  }

  @State private var showModal1 = false
  @State private var showModal2 = false
  @State private var showModal3 = false

  private var backgroundColor: Color {
    .init(light: .init(gray: 0.9), dark: .init(gray: 0.1))
  }

  private func showModalButton(for binding: Binding<Bool>) -> some View {
    Button {
      binding.set(true)
    } label: { config in
      Group {
        RoundedRectangle(cornerRadius: 10)
          .fill(.green)
        Text(binding.get() ? "Hide Modal" : "Show Modal")
          .alignment(.center)
      }
      .opacity(config.isPressed ? 0.5 : (config.isHovered ? 1 : 0.85))
    }
    .width(120)
    .height(40)
    .allowsHitTesting(!binding.get())
    .popover(
      isPresented: binding,
      preferredAnchor: .anchorTo(.bounds, place: .below(alignment: .leading)),
      style: popoverStyle
    ) {
      ModalPanelView {
        binding.set(false)
      }
    }
  }

  private var popoverStyle: PopoverStyle {
    return .init(
      backdropStyle: .transparent,
      borderStyle: .none,
      cornerStyle: .square,
    )
  }
}

private struct ModalPanelView: View {
  let dismiss: () -> Void

  var body: some View {
    Group {
      Color.white
      Color.blue.opacity(0.4)

      Button {
        print(">>> clicked!")
        dismiss()
      } label: { _ in
        Color.pink.opacity(0.4)
      }
      .width(100)
      .height(100)
    }
    .width(400)
    .height(300)
    .shadow(color: .black.opacity(0.5), radius: 10)
  }
}