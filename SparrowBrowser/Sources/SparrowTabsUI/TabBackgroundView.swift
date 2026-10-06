import Foundation
import SparrowDesignSystem
import SparrowUI

struct TabBackgroundView: View {
  init(
    viewModel: TabViewModel,
    contentAlignment: @autoclosure @escaping () -> Alignment,
    contentInsets: @autoclosure @escaping () -> EdgeInsets,
    intendedSize: @autoclosure @escaping () -> CGSize,
    allowHoverEffects: @autoclosure @escaping () -> Bool,
  ) {
    self.viewModel = viewModel
    self.contentAlignment = contentAlignment
    self.contentInsets = contentInsets
    self.intendedSize = intendedSize
    self.allowHoverEffects = allowHoverEffects
  }

  var body: some View {
    Group { geom in
      content
        .padding(contentInsets())
        .width(intendedSize().width - contentInsets().totalHorizontal)
        .height(intendedSize().height - contentInsets().totalVertical)
        .alignment(contentAlignment())
    }
    .clipped()
  }

  private var content: some View {
    RoundedRectangle(cornerRadius: StandardMetrics.buttonCornerRadius)
      .fill(viewModel.isHovered && allowHoverEffects() ? StandardColors.hoverBackground : .clear)
  }

  private let viewModel: TabViewModel
  private let contentAlignment: () -> Alignment
  private let contentInsets: () -> EdgeInsets
  private let intendedSize: () -> CGSize
  private let allowHoverEffects: () -> Bool
}