import Observation
import SparrowTabs
import SparrowToolbelt

/// Each profile has a `SpaceGridModel`. This is a sparse grid of `TabGroupID`,
/// representing a set of distinct spaces (tab sets).
@Observable
@MainActor
public final class SpaceGridModel {
  public init() {}

  public var numRows: Int = 0
  public var numCols: Int = 0

  public struct Key: Hashable {
    public let row: Int
    public let col: Int
  }

  /// The grid of saved spaces (i.e., tab groups) w/ holes.
  public private(set) var savedGroups = [Key: TabGroupID]() {
    didSet {
      guard savedGroups != oldValue else { return }

      var maxRow = 0
      var maxCol = 0

      for key in savedGroups.keys {
        if key.row > maxRow {
          maxRow = key.row
        }
        if key.col > maxCol {
          maxCol = key.col
        }
      }

      numRows = maxRow
      numCols = maxCol
    }
  }
}

extension SpaceGridModel {
  public subscript(row row: Int, col col: Int) -> TabGroupID? {
    get {
      savedGroups[Key(row: row, col: col)]
    }
    set {
      assert(row >= 0)
      assert(col >= 0)
      savedGroups[Key(row: row, col: col)] = newValue
    }
  }
}
