import Foundation
import Observation
import SparrowNetwork

@MainActor
public protocol SuggestQuery: AnyObject {
  var model: SuggestQueryModel { get }

  func cancel()
}

final class DefaultSuggestQuery: SuggestQuery {
  init(input: String, networkRequest: NetworkRequest) {
    self.networkRequest = networkRequest
    model = .init(input: input)

    // TODO: Implement something for real.
    queryTask = .init {
      guard !Task.isCancelled, model.status == .pending else {
        print(">>> task cancelled at A")
        return
      }

      for await status in Observations({
        networkRequest.model.status
      }) {
        if status == .done {
          print(">>> network request is done, data.count: \(networkRequest.model.data?.count ?? 0)")
          break
        }
      }

      guard !Task.isCancelled, model.status == .pending else {
        print(">>> task cancelled at B")
        return
      }

      let completions: [String] =
        if let data = networkRequest.model.data {
          await withCheckedContinuation { continuation in
            DispatchQueue(label: "google-suggest-deserializer").async {
              continuation.resume(returning: deserializeGoogleSuggestResult(data: data))
            }
          }
        } else {
          []
        }

      guard !Task.isCancelled, model.status == .pending else {
        print(">>> task cancelled at C")
        return
      }

      print(">>> got completions: \(model.completions)")

      model.completions = completions
      model.status = .done
      queryTask = nil
    }
  }

  let model: SuggestQueryModel

  func cancel() {
    print(">>> cancel suggest query!")

    queryTask?.cancel()
    queryTask = nil

    model.status = .done
  }

  private let networkRequest: NetworkRequest
  private var queryTask: Task<Void, Never>?
}

func deserializeGoogleSuggestResult(data: Data) -> [String] {
  do {
    let json = try JSONSerialization.jsonObject(with: data) as! [Any]
    return json[1] as! [String]
  } catch {
    print(">>> JSON deserialization of google suggest result failed: \(error)")
    return []
  }
}