import Foundation
import SparrowUICore

public struct RoundedRectangle: Shape {
  public init(cornerRadius: @autoclosure @MainActor @escaping () -> CGFloat) {
    self.cornerRadius = cornerRadius
  }

  public func path(in rect: CGRect) -> Path {
    .init(roundedRect: rect, cornerRadius: cornerRadius())
  }

  private let cornerRadius: @MainActor () -> CGFloat
}
