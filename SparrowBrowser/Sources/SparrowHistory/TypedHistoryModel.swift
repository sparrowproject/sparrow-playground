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
  private var freeIndices = [Int]()

  mutating func insert(_ record: TypedHistoryRecord) {
    var index = 0
    nodes[index].record = record
    for character in record.value {
      if let child = nodes[index].children[character] {
        index = child
      } else {
        let child: Int
        if let freeIndex = freeIndices.popLast() {
          child = freeIndex
        } else {
          child = nodes.count
          nodes.append(Node())
        }
        nodes[index].children[character] = child
        index = child
      }
      nodes[index].record = record
    }
  }

  /// Only valid for the oldest record: any retained match must already be newer.
  mutating func removeOldest(_ record: TypedHistoryRecord) {
    var path = [(parent: Int, character: Character, child: Int)]()
    var index = 0
    if nodes[index].record?.value == record.value {
      nodes[index].record = nil
    }
    for character in record.value {
      guard let child = nodes[index].children[character] else {
        preconditionFailure("Missing oldest record in typed history trie")
      }
      path.append((index, character, child))
      index = child
      if nodes[index].record?.value == record.value {
        nodes[index].record = nil
      }
    }
    for edge in path.reversed() {
      guard nodes[edge.child].record == nil, nodes[edge.child].children.isEmpty else { break }
      nodes[edge.parent].children.removeValue(forKey: edge.character)
      nodes[edge.child] = Node()
      freeIndices.append(edge.child)
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
