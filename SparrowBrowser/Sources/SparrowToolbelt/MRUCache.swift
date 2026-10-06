/// A bounded dictionary that retains the most recently used entries.
///
/// Reading or writing a key makes it the most recently used entry. Inserting a
/// new key into a full cache evicts the least recently used entry. Iteration and
/// inspecting `keys` or `values` do not change recency and have no defined order.
/// Like `Dictionary`, copies have independent value semantics. Reads through
/// subscripts are mutating because they update recency.
public struct MRUCache<Key: Hashable, Value>: Sequence {
  private struct Entry {
    var value: Value
    var older: Key?
    var newer: Key?
  }

  private var entries: [Key: Entry] = [:]
  private var oldest: Key?
  private var newest: Key?

  /// The maximum number of entries. Zero creates a cache that stores nothing.
  public let maxCount: Int

  public init(maxCount: Int) {
    precondition(maxCount >= 0, "MRUCache maxCount must be nonnegative")
    self.maxCount = maxCount
  }

  public var count: Int { entries.count }
  public var isEmpty: Bool { entries.isEmpty }
  public var keys: some Collection<Key> { entries.keys }
  public var values: [Value] { entries.values.map(\.value) }

  public subscript(key: Key) -> Value? {
    mutating get {
      guard let entry = entries[key] else { return nil }
      touch(key)
      return entry.value
    }
    set {
      if let value = newValue {
        updateValue(value, forKey: key)
      } else {
        removeValue(forKey: key)
      }
    }
  }

  public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
    mutating get { self[key] ?? defaultValue() }
    set { self[key] = newValue }
  }

  @discardableResult
  public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
    if let entry = entries[key] {
      entries[key]?.value = value
      touch(key)
      return entry.value
    }
    guard maxCount > 0 else { return nil }
    if count == maxCount, let oldest {
      removeValue(forKey: oldest)
    }
    entries[key] = Entry(value: value, older: newest, newer: nil)
    if let newest { entries[newest]?.newer = key }
    if oldest == nil { oldest = key }
    newest = key
    return nil
  }

  @discardableResult
  public mutating func removeValue(forKey key: Key) -> Value? {
    guard let entry = entries.removeValue(forKey: key) else { return nil }
    unlink(entry)
    return entry.value
  }

  public mutating func removeAll(keepingCapacity: Bool = false) {
    entries.removeAll(keepingCapacity: keepingCapacity)
    oldest = nil
    newest = nil
  }

  public func makeIterator() -> AnyIterator<(key: Key, value: Value)> {
    var iterator = entries.makeIterator()
    return AnyIterator {
      guard let (key, entry) = iterator.next() else { return nil }
      return (key: key, value: entry.value)
    }
  }

  private mutating func touch(_ key: Key) {
    guard newest != key, let entry = entries[key] else { return }
    unlink(entry)
    entries[key]?.older = newest
    entries[key]?.newer = nil
    if let newest { entries[newest]?.newer = key }
    newest = key
  }

  private mutating func unlink(_ entry: Entry) {
    if let older = entry.older {
      entries[older]?.newer = entry.newer
    } else {
      oldest = entry.newer
    }
    if let newer = entry.newer {
      entries[newer]?.older = entry.older
    } else {
      newest = entry.older
    }
  }
}
