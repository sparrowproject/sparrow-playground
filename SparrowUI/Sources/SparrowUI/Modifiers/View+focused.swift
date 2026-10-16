import SparrowUICore
import SparrowUIFoundation

extension View {
  public func focused<Value>(
    when binding: Binding<Value?>,
    equals value: Value,
  ) -> some View where Value: Equatable {
    modifier(_FocusedModifier(binding: binding, value: value))
  }
}

@MainActor
public struct _FocusedModifier<Value> where Value: Equatable {
  let binding: Binding<Value?>
  let value: Value
}

extension _FocusedModifier: ViewModifier {
  public typealias Body = Never
}

extension _FocusedModifier: PrimitiveViewModifier {
  func apply(to view: CoreView) {
    // TODO: These need to only be active when visible.

    view.onChange(
      of: {
        binding.get() == value
      },
      perform: { [weak view] in
        guard let view else { return }
        if $0, let focusableView = view.findFocusableView() {
          view.context.focusedView = focusableView
        }
      },
      cancellable: false,
    )

    view.onChange(
      of: { [weak view] in
        view?.context.focusedView
      },
      perform: { [weak view] in
        guard let view else { return }

        if $0 == nil {
          binding.set(nil)
        }

        // Satisfy this binding even if the focused view is a descendent.
        var focusedView: CoreView? = $0
        while focusedView != nil {
          if focusedView === view {
            binding.set(value)
            break
          }
          focusedView = focusedView?.superview
        }
      },
      cancellable: false,
    )
  }
}
