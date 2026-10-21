import Foundation
import SparrowDesignSystem
import SparrowSuggest
import SparrowUI

struct SuggestionIconView: View {
  enum Metrics {
    static let iconSize: CGFloat = 13
  }

  init(for result: @autoclosure @MainActor @escaping () -> SuggestQueryResult?) {
    self.result = result
  }

  var body: some View {
    FaviconView(source: source)
      .width(Metrics.iconSize)
      .height(Metrics.iconSize)
      // TODO: Consider a better way to specify this. It's a bit fragile as the goal here is to
      // match internal behavior of `FaviconView`.
      .opacity(opacity)
      .readColorScheme(to: $colorScheme)
  }

  private let result: @MainActor () -> SuggestQueryResult?
  @State private var colorScheme = ColorScheme.light

  private var source: ImageSource {
    switch result() {
    case .search, .none:
      .symbol(StandardSymbols.search)
    case .chat:
      .symbol(StandardSymbols.chat)
    case .navigation(let url, _):
      .pageFavicon(pageURL: url, colorScheme: colorScheme)
    }
  }

  private var opacity: CGFloat {
    switch result() {
    case .search, .chat, .none:
      0.7
    case .navigation:
      1
    }
  }
}