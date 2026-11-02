import Observation

@MainActor
public protocol TabAttribute: Observable {
  associatedtype Key: Hashable
  static var key: Key { get }
}

public typealias AnyTabAttribute = any TabAttribute