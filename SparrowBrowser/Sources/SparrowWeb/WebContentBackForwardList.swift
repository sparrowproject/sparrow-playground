import Foundation

@MainActor
public protocol WebContentBackForwardList {
  associatedtype Item: WebContentBackForwardListItem

  var currentItem: Item? { get }
  var backList: [Item] { get }
  var forwardList: [Item] { get }
}

@MainActor
public protocol WebContentBackForwardListItem {
  var url: URL { get }
  var title: String? { get }
}