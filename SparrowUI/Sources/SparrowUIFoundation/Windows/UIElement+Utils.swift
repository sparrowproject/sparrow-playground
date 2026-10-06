#if os(Windows)
import WinAppSDK
import WinUI

extension UIElement {
  public var windowId: WindowId? {
    xamlRoot?.contentIslandEnvironment?.appWindowId

    // let visual = try! ElementCompositionPreview.getElementVisual(self)!

    // guard let island = try! ContentIsland.getByVisual(visual) else {
    //   return nil
    // }

    // return island.environment.appWindowId
  }

  public var appWindow: AppWindow? {
    windowId.flatMap { try? AppWindow.getFromWindowId($0) }
  }

  public var visualRoot: UIElement? {
    var current: DependencyObject? = self
    while true {
      let parent = try! VisualTreeHelper.getParent(current)
      if parent == nil {
        return current as? UIElement
      }
      current = parent
    }
  }
}

#endif