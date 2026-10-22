import Observation
import OrderedCollections

@Observable
@MainActor
public final class TypedHistoryModel {
  /// Unique by value, ordered from least to most recently stored.
  public internal(set) var records = OrderedDictionary<String, TypedHistoryRecord>()
  var trie = TypedHistoryTrie()
}

/// Caches the most recently stored record at every prefix, including the empty prefix.
struct TypedHistoryTrie {
  private struct Node {
    var children = [Character: Int]()
    var record: TypedHistoryRecord?
  }

  private var nodes = [Node()]

  mutating func insert(_ record: TypedHistoryRecord) {
    var index = 0
    nodes[index].record = record
    for character in record.value {
      if let child = nodes[index].children[character] {
        index = child
      } else {
        let child = nodes.count
        nodes.append(Node())
        nodes[index].children[character] = child
        index = child
      }
      nodes[index].record = record
    }
  }

  func record(matching prefix: String) -> TypedHistoryRecord? {
    var index = 0
    for character in prefix {
      guard let child = nodes[index].children[character] else { return nil }
      index = child
    }
    return nodes[index].record
  }
}
