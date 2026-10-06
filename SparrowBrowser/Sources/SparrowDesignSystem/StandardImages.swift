import SparrowUIFoundation

@MainActor
public enum StandardImages {
  public static var defaultFavicon: ImageSource {
    .resource(named: "globe-favicon-thin", withExtension: "svg")
  }
}
