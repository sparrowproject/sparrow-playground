import Foundation
import SparrowUI
import SparrowUIFoundation

enum ImageSourceKinds: String {
  case favicon
  case pageFavicon
}

extension ImageSource {
  /// Favicon indexed by URL of the favicon.
  public static func favicon(url faviconURL: URL) -> ImageSource {
    .custom(kind: ImageSourceKinds.favicon.rawValue, id: faviconURL.absoluteString)
  }

  /// Favicon indexed by URL of the associated web page & color scheme.
  public static func pageFavicon(pageURL: URL, colorScheme: ColorScheme) -> ImageSource {
    let id = "\(colorScheme.rawValue):\(pageURL.absoluteString)"
    return .custom(kind: ImageSourceKinds.pageFavicon.rawValue, id: id)
  }
}

extension WebHistory {
  public var faviconImageSource: FaviconImageSource {
    .init(webHistory: self)
  }

  public var pageFaviconImageSource: PageFaviconImageSource {
    .init(webHistory: self)
  }
}

public struct FaviconImageSource: CustomImageSource {
  public var kind: String { ImageSourceKinds.favicon.rawValue }

  public func resolve(id: String) -> _LazyFaviconProvider? {
    .init(webHistory: webHistory, id: id)
  }

  let webHistory: WebHistory
}

public struct _LazyFaviconProvider: ImageProvider {
  let webHistory: WebHistory
  let id: String

  public func getImage() async -> ImageRef? {
    guard let faviconURL = URL(string: id) else {
      print(">>> invalid favicon url!")
      return nil
    }

    guard let imageProvider = await webHistory.queryImage(forFaviconURL: faviconURL) else {
      print(">>> image for favicon not found!")
      return nil
    }

    return await imageProvider.getImage()
  }
}

public struct PageFaviconImageSource: CustomImageSource {
  public var kind: String { ImageSourceKinds.pageFavicon.rawValue }

  public func resolve(id: String) -> _LazyPageFaviconProvider? {
    .init(webHistory: webHistory, id: id)
  }

  let webHistory: WebHistory
}

public struct _LazyPageFaviconProvider: ImageProvider {
  let webHistory: WebHistory
  let id: String

  public func getImage() async -> ImageRef? {
    let parts = id.split(separator: ":", maxSplits: 1)

    guard let colorScheme = ColorScheme(rawValue: String(parts[0])) else {
      print(">>> invalid color scheme!")
      return nil
    }

    guard let pageURL = URL(string: String(parts[1])) else {
      print(">>> invalid page url!")
      return nil
    }

    guard let faviconURL = await webHistory.queryFaviconURL(forPageURL: pageURL, withColorScheme: colorScheme) else {
      print(">>> favicon for page not found!")
      return nil
    }

    guard let imageProvider = await webHistory.queryImage(forFaviconURL: faviconURL) else {
      print(">>> image for favicon not found!")
      return nil
    }

    return await imageProvider.getImage()
  }
}
