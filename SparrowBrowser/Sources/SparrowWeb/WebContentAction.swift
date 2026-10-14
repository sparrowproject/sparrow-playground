import SparrowUIFoundation

@MainActor
public enum WebContentAction {
  case createdNew(WebContent, modifierFlags: Keystroke.ModifierFlags)
  case downloadStarting(WebDownload)
}