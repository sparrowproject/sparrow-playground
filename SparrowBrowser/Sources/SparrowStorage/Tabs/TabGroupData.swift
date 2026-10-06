import SparrowTabs

struct TabGroupData: Codable, Sendable, Equatable {
  let id: TabGroupID
  let tabIDs: [TabID]
  let selectedTabID: TabID?
}