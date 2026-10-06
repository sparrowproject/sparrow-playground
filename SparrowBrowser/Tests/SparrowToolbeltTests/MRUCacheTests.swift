import SparrowToolbelt

enum MRUCacheTests {
  static func run() {
    var cache = MRUCache<String, Int>(maxCount: 3)
    precondition(cache.isEmpty)
    cache["a"] = 1
    cache["b"] = 2
    cache["c"] = 3
    precondition(cache["a"] == 1)
    cache["d"] = 4
    precondition(cache["b"] == nil, "Reading a key must protect it from eviction")
    precondition(cache.count == 3)

    precondition(cache.updateValue(10, forKey: "a") == 1)
    cache["e"] = 5
    precondition(cache["c"] == nil, "Updating a key must refresh its recency")
    precondition(cache["a"] == 10)

    var copy = cache
    precondition(copy.removeValue(forKey: "a") == 10)
    precondition(cache["a"] == 10, "Copies must have independent storage")
    copy["d"] = nil
    copy["e"] = nil
    precondition(copy.isEmpty)
    copy["f", default: 0] += 1
    precondition(copy["f"] == 1)
    precondition(copy["missing", default: 42] == 42)
    precondition(copy.count == 1, "Reading a default must not insert it")
    precondition(copy["f", default: { preconditionFailure("Default must be lazy") }()] == 1)

    cache.removeAll(keepingCapacity: true)
    cache["a"] = 1
    cache["b"] = 2
    cache["c"] = 3
    precondition(Set(cache.keys) == ["a", "b", "c"])
    precondition(Set(cache.values) == [1, 2, 3])
    precondition(Dictionary(uniqueKeysWithValues: cache.map { ($0.key, $0.value) }) == ["a": 1, "b": 2, "c": 3])
    cache["d"] = 4
    precondition(cache["a"] == nil, "Iteration must not refresh recency")

    // Remove the middle, newest, and oldest entries, then reuse the cache.
    precondition(cache.removeValue(forKey: "c") == 3)
    precondition(cache.removeValue(forKey: "d") == 4)
    precondition(cache.removeValue(forKey: "b") == 2)
    precondition(cache.removeValue(forKey: "missing") == nil)
    cache["x"] = 7
    precondition(cache["x"] == 7)

    var single = MRUCache<Int, Int>(maxCount: 1)
    single[1] = 1
    single[2] = 2
    precondition(single[1] == nil && single[2] == 2)
    single.removeAll()
    precondition(single.isEmpty)

    var empty = MRUCache<Int, Int>(maxCount: 0)
    empty[1] = 1
    empty[2, default: 0] += 1
    precondition(empty.isEmpty)

    var optional = MRUCache<Int?, Int?>(maxCount: 2)
    optional.updateValue(nil, forKey: nil)
    optional[1] = 1
    precondition(optional[nil] != nil, "Optional keys and values must be supported")
    optional[2] = 2
    precondition(optional[1] == nil)
    precondition(optional.count == 2)
  }
}
