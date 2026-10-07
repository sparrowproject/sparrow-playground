@MainActor
public enum WebContentAction {
  case createdNew(WebContent)
  case downloadStarting(WebDownload)
}