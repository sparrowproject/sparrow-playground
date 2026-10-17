import SparrowUIFoundation
import SparrowWeb

@MainActor
public protocol TabSystemDelegate: AnyObject {
  func newTabRequested(byTab: TabID, modifierFlags: Keystroke.ModifierFlags, completion: (TabSystemNewTabPolicy) -> Void)

  func startDownload(_: WebDownload, fromTab: TabID)

  // func performWithAnimation(currentIndex: Int?, newIndex: Int?, completion: () -> Void)

  func didSelectTab(atIndex: Int?, previousIndex: Int?)
}

@MainActor
public enum TabSystemNewTabPolicy: Equatable {
  case cancel
  case `continue`
  case continueWithGroup(TabGroupID)
}