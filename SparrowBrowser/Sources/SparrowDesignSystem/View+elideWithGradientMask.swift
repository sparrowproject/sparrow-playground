import Foundation
import SparrowUI

extension View {
  public func elideWithGradientMask() -> some View {
    modifier(ElideWithGradientMaskModifier())
  }
}

struct ElideWithGradientMaskModifier: ViewModifier {
  func body(content: Content) -> some View {
    Group {
      content
        .readSize(to: $contentSize)
        .alignment(.leading)
    }
    .clipped()
    .mask(gradientMask)
    .readSize(to: $viewportSize)
  }

  private enum Metrics {
    static let gradientWidth: CGFloat = 20 // TODO: Make this configurable.
  }

  private var gradientMask: some View {
    LinearGradient(
      stops: gradientStops,
      startPoint: .leading,
      endPoint: .trailing,
    )
  }

  private var gradientStops: [Gradient.Stop] {
    if contentSize.width < viewportSize.width {
      return [
        .init(color: .black, location: 0),
        .init(color: .black, location: 1),
      ]
    } else if viewportSize.width < Metrics.gradientWidth {
      return [
        .init(color: .black.opacity(viewportSize.width / Metrics.gradientWidth), location: 0),
        .init(color: .clear, location: 1),
      ]
    } else {
      // [ black | gradient ]
      let offset: CGFloat = viewportSize.width - Metrics.gradientWidth
      return [
        .init(color: .black, location: 0),
        .init(color: .black, location: offset / viewportSize.width),
        .init(color: .clear, location: 1),
      ]
    }
  }

  @State private var contentSize = CGSize.zero
  @State private var viewportSize = CGSize.zero
}