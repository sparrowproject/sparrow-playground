@MainActor
public enum WebContentAction {
  case createdNew(WebContent)
  case downloadStarted(WebDownload)
}