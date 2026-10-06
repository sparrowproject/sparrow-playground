import Foundation
import Observation

@Observable
@MainActor
public final class NetworkRequestModel {
  public enum Status: Sendable, Equatable {
    case pending
    case done
  }

  public let url: URL

  public internal(set) var status = Status.pending
  public internal(set) var data: Data?

  init(url: URL) {
    self.url = url
  }
}