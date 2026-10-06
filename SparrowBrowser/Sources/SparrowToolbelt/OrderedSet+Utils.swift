import OrderedCollections

extension OrderedSet {
  public mutating func move(
    _ element: Element,
    before target: Element
  ) {
    guard
      let sourceIndex = firstIndex(of: element),
      let targetIndex = firstIndex(of: target),
      sourceIndex != targetIndex
    else {
      return
    }

    let value = remove(at: sourceIndex)

    let destination =
      sourceIndex < targetIndex
      ? targetIndex - 1
      : targetIndex

    insert(value, at: destination)
  }

  public mutating func move(
    _ element: Element,
    toPositionOf target: Element
  ) {
    guard
      let sourceIndex = firstIndex(of: element),
      let targetIndex = firstIndex(of: target),
      sourceIndex != targetIndex
    else {
      return
    }
    insert(remove(at: sourceIndex), at: targetIndex)
  }

  public subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}