import SparrowTabs

struct SpaceData: Codable, Sendable, Equatable {
  struct Key: Codable, Sendable, Equatable, Hashable {
    let row: Int
    let col: Int
  }
  var elements = [Key: TabGroupID]()
}