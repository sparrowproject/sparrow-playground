import Observation
import SparrowUIFoundation

@MainActor
public protocol Command: AnyObject, Observable {
  var title: String { get }
  var icon: ImageSource? { get }

  var isEnabled: Bool { get }
  var isToggled: Bool { get }

  var keybinding: Keybinding? { get }
}

extension Command {
  public var icon: ImageSource? { nil }
  public var isEnabled: Bool { true }
  public var isToggled: Bool { false }
  public var keybinding: Keybinding? { nil }
}