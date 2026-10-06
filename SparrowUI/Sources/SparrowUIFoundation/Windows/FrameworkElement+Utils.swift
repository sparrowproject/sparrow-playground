#if os(Windows)
import WinUI

extension FrameworkElement {
  public func whenLoaded(perform work: @escaping () -> Void) {
    if xamlRoot != nil {
      work()
    } else {
      loaded.addHandler { _, _ in
        work()
      }
    }
  }
}

#endif