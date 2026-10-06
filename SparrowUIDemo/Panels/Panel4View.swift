import Foundation
import SparrowUI

struct Panel4View: PanelView {
  var body: some View {
    Group { geom in
      background
      Group {
        preview
          .offset(x: Metrics.padding)
        editor
          .offset(y: Metrics.rowHeight)
        selectionView
          .offset(x: Metrics.padding, y: 2 * Metrics.rowHeight)
      }
      .height(3 * Metrics.rowHeight)
      .padding(.horizontal, 12)
      .alignment(.leading)
    }
  }

  private enum Metrics {
    static let padding: CGFloat = 8
    static let rowHeight: CGFloat = 36
  }

  @State private var text: String = "Hello, world!"
  @State private var selection: Range<String.Index>?

  private var background: some View {
    Color(.init(gray: 0.9))
  }

  private var preview: some View {
    Group {
      Text(text)
        .font(.system(size: 12))
        .alignment(.leading)
    }
    .height(Metrics.rowHeight)
  }

  private var editor: some View {
    Group {
      RoundedRectangle(cornerRadius: Metrics.padding)
        .fill(Color.white)
      textView
        .alignment(.leading)
    }
    .height(Metrics.rowHeight)
    // .shadow(color: .black.opacity(0.2), radius: 10, x: 4, y: 4)
  }

  private var selectionView: some View {
    Group {
      Text("Selected range: \(selection?.description ?? "none")")
        .font(.system(size: 12))
        .alignment(.leading)
    }
    .height(Metrics.rowHeight)
  }

  private var textView: some View {
    TextEditor(
      text: $text,
      selection: $selection,
    )
    .font(.system(size: 12))
    .foregroundColor(.red)
    .contentPadding(.horizontal, Metrics.padding)
  }
}