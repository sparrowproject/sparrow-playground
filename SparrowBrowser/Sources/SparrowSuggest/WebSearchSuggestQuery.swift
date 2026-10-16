import Foundation
import Observation
import SparrowNetwork

public typealias WebSearchSuggestQueryDependencies
  = NetworkServiceProviding

final class WebSearchSuggestQuery: SuggestQuery {
  init(dependencies: WebSearchSuggestQueryDependencies, input: String) {
    var components = URLComponents(
      string: "https://suggestqueries.google.com/complete/search"
    )!
    components.queryItems = [
      URLQueryItem(name: "client", value: "firefox"),
      URLQueryItem(name: "q", value: input)
    ]

    networkRequest = dependencies.networkService.load(url: components.url!)
    model = .init(input: input)

    queryTask = .init { [networkRequest] in
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
            DispatchQueue(label: "web-search-suggest-deserializer").async {
              continuation.resume(returning: deserializeWebSearchSuggestResult(data: data))
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

func deserializeWebSearchSuggestResult(data: Data) -> [String] {
  do {
    let json = try JSONSerialization.jsonObject(with: data) as! [Any]
    return json[1] as! [String]
  } catch {
    print(">>> JSON deserialization of web search suggest result failed: \(error)")
    return []
  }
}