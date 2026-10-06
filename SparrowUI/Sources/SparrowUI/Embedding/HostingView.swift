@MainActor
protocol HostingView {
  var eventRouter: EventRouter { get }

  func pushEventRouter(_: EventRouter)
  func popEventRouter(_: EventRouter)
}