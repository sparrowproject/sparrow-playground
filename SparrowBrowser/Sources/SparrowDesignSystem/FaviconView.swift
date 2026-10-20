import SparrowUI
import SparrowUIFoundation

public struct FaviconView: View {
  public init(source: @autoclosure @MainActor @escaping () -> ImageSource?) {
    self.source = source
  }

  public var body: some View {
    Group { geom in
      primaryContent
        .width(geom.width)
        .height(geom.height)

      fallbackContent
        .width(geom.width)
        .height(geom.height)
    }
  }

  private let source: @MainActor () -> ImageSource?
  @State private var loadingStatus = ImageLoadingStatus.idle

  private var primaryContent: some View {
    Image(source: source())
      .resizable()
      .readLoadingStatus(to: $loadingStatus)
      .opacity(showFallbackContent ? 0 : 1)
  }

  private var fallbackContent: some View {
    Image(source: StandardImages.defaultFavicon)
      .resizable()
      .tintColor(.primaryText.opacity(0.7))
      .opacity(showFallbackContent ? 1 : 0)
  }

  private var showFallbackContent: Bool {
    loadingStatus != .loaded
  }
}