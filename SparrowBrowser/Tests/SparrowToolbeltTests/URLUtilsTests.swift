import Foundation
import SparrowToolbelt

@main
struct URLUtilsTests {
  static func main() {
    var failures = 0

    MRUCacheTests.run()

    testSearchQueryFromWords(&failures)
    testURLFromHostname(&failures)
    testURLFromExplicitScheme(&failures)
    testSearchQueryFromSingleWord(&failures)
    testSearchQueryFromInvalidHostname(&failures)

    precondition(failures == 0, "\(failures) test expectation(s) failed")
  }

  private static func testSearchQueryFromWords(_ failures: inout Int) {
    guard let url = URL.fromUserInput("foo bar") else {
      fail("Expected foo bar to produce a search URL", &failures)
      return
    }

    expectEqual(url.scheme, "https", "Expected search URL scheme", &failures)
    expectEqual(url.host, "www.google.com", "Expected search URL host", &failures)
    expectEqual(url.path, "/search", "Expected search URL path", &failures)

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    expectEqual(components?.queryItems?.first(where: { $0.name == "q" })?.value, "foo bar", "Expected search query", &failures)
  }

  private static func testURLFromHostname(_ failures: inout Int) {
    expectEqual(URL.fromUserInput("foo.com")?.absoluteString, "https://foo.com", "Expected hostname to become HTTPS URL", &failures)
    expectEqual(URL.fromUserInput("foo.com/path?q=bar")?.absoluteString, "https://foo.com/path?q=bar", "Expected hostname path to be preserved", &failures)
  }

  private static func testURLFromExplicitScheme(_ failures: inout Int) {
    expectEqual(URL.fromUserInput("https://foo.com")?.absoluteString, "https://foo.com", "Expected explicit HTTPS URL", &failures)
    expectEqual(URL.fromUserInput("mailto:user@example.com")?.absoluteString, "mailto:user@example.com", "Expected explicit non-HTTP URL", &failures)
  }

  private static func testSearchQueryFromSingleWord(_ failures: inout Int) {
    guard let url = URL.fromUserInput("foo") else {
      fail("Expected foo to produce a search URL", &failures)
      return
    }

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    expectEqual(components?.queryItems?.first(where: { $0.name == "q" })?.value, "foo", "Expected single word search query", &failures)
  }

  private static func testSearchQueryFromInvalidHostname(_ failures: inout Int) {
    guard let url = URL.fromUserInput("foo..com") else {
      fail("Expected invalid hostname to produce a search URL", &failures)
      return
    }

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    expectEqual(components?.queryItems?.first(where: { $0.name == "q" })?.value, "foo..com", "Expected invalid hostname search query", &failures)
  }

  private static func expectEqual<T: Equatable>(_ actual: T?, _ expected: T, _ message: String, _ failures: inout Int) {
    guard actual == expected else {
      fail("\(message): expected \(expected), got \(String(describing: actual))", &failures)
      return
    }
  }

  private static func fail(_ message: String, _ failures: inout Int) {
    failures += 1
    print("FAIL: \(message)")
  }
}
