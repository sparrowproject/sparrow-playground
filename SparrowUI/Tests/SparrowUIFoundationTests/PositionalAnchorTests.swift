import Foundation
import SparrowUIFoundation

@main
struct PositionalAnchorTests {
  static func main() {
    var failures = 0

    testTopLeadingAtBottomTrailing(&failures)
    testCenterAtCenter(&failures)
    testBottomTrailingAtTopLeading(&failures)
    testCustomUnitPoints(&failures)

    precondition(failures == 0, "\(failures) test expectation(s) failed")
  }

  private static func testTopLeadingAtBottomTrailing(_ failures: inout Int) {
    let rect = PositionalAnchor.place(.topLeading, at: .bottomTrailing)
      .computeRect(ofSize: CGSize(width: 20, height: 10), relativeTo: CGRect(x: 10, y: 20, width: 100, height: 50))

    expectEqual(rect, CGRect(x: 110, y: 70, width: 20, height: 10), "Expected top-leading origin at anchor bottom-trailing", &failures)
  }

  private static func testCenterAtCenter(_ failures: inout Int) {
    let rect = PositionalAnchor.place(.center, at: .center)
      .computeRect(ofSize: CGSize(width: 20, height: 10), relativeTo: CGRect(x: 10, y: 20, width: 100, height: 50))

    expectEqual(rect, CGRect(x: 50, y: 40, width: 20, height: 10), "Expected centered rect", &failures)
  }

  private static func testBottomTrailingAtTopLeading(_ failures: inout Int) {
    let rect = PositionalAnchor.place(.bottomTrailing, at: .topLeading)
      .computeRect(ofSize: CGSize(width: 20, height: 10), relativeTo: CGRect(x: 10, y: 20, width: 100, height: 50))

    expectEqual(rect, CGRect(x: -10, y: 10, width: 20, height: 10), "Expected bottom-trailing origin at anchor top-leading", &failures)
  }

  private static func testCustomUnitPoints(_ failures: inout Int) {
    let anchor = PositionalAnchor.place(UnitPoint(x: 0.25, y: 0.75), at: UnitPoint(x: 0.8, y: 0.2))
    let rect = anchor.computeRect(ofSize: CGSize(width: 40, height: 20), relativeTo: CGRect(x: 5, y: 10, width: 50, height: 100))

    expectEqual(rect, CGRect(x: 35, y: 15, width: 40, height: 20), "Expected custom unit point placement", &failures)
  }

  private static func expectEqual(_ actual: CGRect, _ expected: CGRect, _ message: String, _ failures: inout Int) {
    guard actual == expected else {
      fail("\(message): expected \(expected), got \(actual)", &failures)
      return
    }
  }

  private static func fail(_ message: String, _ failures: inout Int) {
    failures += 1
    print("FAIL: \(message)")
  }
}
