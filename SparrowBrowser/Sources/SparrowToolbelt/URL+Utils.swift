import Foundation

extension URL {
  public static func fromUserInput(_ string: String) -> URL? {
    let input = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !input.isEmpty else { return nil }

    if input.startsWithURLScheme {
      return URL(string: input)
    }

    if input.looksLikeHostnameURLInput {
      return URL(string: "https://\(input)")
    }

    return googleSearchURL(for: input)
  }

  public static func googleSearchURL(for query: String) -> URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "www.google.com"
    components.path = "/search"
    components.queryItems = [
      URLQueryItem(name: "q", value: query)
    ]
    return components.url
  }
}

private extension String {
  var startsWithURLScheme: Bool {
    guard let colonIndex = firstIndex(of: ":") else { return false }
    guard colonIndex > startIndex else { return false }

    for character in self[..<colonIndex] {
      guard character.isASCII else { return false }
      guard character.isLetter || character.isNumber || character == "+" || character == "-" || character == "." else {
        return false
      }
    }

    return self[startIndex].isLetter
  }

  var looksLikeHostnameURLInput: Bool {
    guard !contains(where: \.isWhitespace) else { return false }

    guard let components = URLComponents(string: "https://\(self)"),
          let host = components.host,
          host.looksLikeHostname else {
      return false
    }

    return true
  }

  var looksLikeHostname: Bool {
    guard contains(".") else { return false }
    guard !hasPrefix("."), !hasSuffix(".") else { return false }

    return split(separator: ".", omittingEmptySubsequences: false).allSatisfy { label in
      guard !label.isEmpty else { return false }
      guard label.first?.isHostnameLabelBoundary == true, label.last?.isHostnameLabelBoundary == true else { return false }

      return label.allSatisfy { character in
        character.isASCII && (character.isHostnameLabelBoundary || character == "-")
      }
    }
  }
}

private extension Character {
  var isHostnameLabelBoundary: Bool {
    isLetter || isNumber
  }
}
