#if os(Windows)
import Foundation
import WindowsFoundation

extension TimeSpan {
  public init(_ interval: TimeInterval) {
    self.init(duration: Int64(interval * 10_000_000))
  }
}

#endif