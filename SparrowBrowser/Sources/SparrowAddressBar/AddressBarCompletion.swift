import Foundation
import SparrowHistory
import SparrowSuggest

public struct AddressBarCompletion: Sendable, Equatable {
  public let url: URL
  public let typedHistoryRecord: TypedHistoryRecord?
}

extension AddressBarCompletion {
  init?(_ result: SuggestQueryResult) {
    guard let url = result.url else { return nil }

    let kind: TypedHistoryRecord.Kind =
      switch result.kind {
      case .navigation:
        .navigation
      case .search:
        .search
      case .chat:
        .chat
      }

    self.init(
      url: url,
      typedHistoryRecord: result.representsInput ? .init(kind: kind, value: result.value) : nil,
    )
  }
}