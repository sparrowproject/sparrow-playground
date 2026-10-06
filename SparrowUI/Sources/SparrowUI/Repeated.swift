import Foundation
import SparrowUICore

public struct Repeated<Data, ID, Content> where Data: RandomAccessCollection, ID: Hashable, Content: View {
  public init(
    _ data: @autoclosure @MainActor @escaping () -> Data,
    id: KeyPath<Data.Element, ID>,
    content: @escaping (Data.Element) -> Content,
  ) {
    self.data = data
    self.id = id
    self.content = content
  }

  public init(
    _ data: @autoclosure @MainActor @escaping () -> Data,
    content: @escaping (Data.Element) -> Content,
  ) where Data.Element: Identifiable, Data.Element.ID == ID {
    self.init(data(), id: \.id, content: content)
  }

  private let data: @MainActor () -> Data
  private let id: KeyPath<Data.Element, ID>
  private let content: (Data.Element) -> Content
}

extension Repeated: View {
  public typealias Body = Never
}

extension Repeated: PrimitiveView {
  func buildView(context: CoreViewContext) -> CoreView {
    let view = CoreView(context: context)
    view.subviews = { [weak view] in
      guard let view else { return [] }
      // Avoid re-creating views that are still included.
      var updatedSubviewMap: [AnyHashable: CoreView] = [:]
      let result = data().map { (element: Data.Element) -> CoreView in
        let subview = view.subviewMap[element[keyPath: id]] ?? ViewBuilder(content: content(element)).buildView(context: context)
        updatedSubviewMap[element[keyPath: id]] = subview
        return subview
      }
      view.subviewMap = updatedSubviewMap
      return result
    }
    return view
  }
}
