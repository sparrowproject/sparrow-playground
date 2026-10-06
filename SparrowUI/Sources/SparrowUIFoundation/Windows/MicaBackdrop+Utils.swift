#if os(Windows)
import WinAppSDK
import WinUI

extension MicaBackdrop {
  public convenience init(kind: MicaKind) {
    self.init()
    self.kind = kind
  }
}

#endif