import Foundation
import SparrowDownloads
import SparrowSpaces
import SparrowTabs
import SparrowToolbelt
import SparrowUI
import SparrowUICore
import SparrowUIFoundation
import SparrowWeb
import SparrowWindowModel

typealias ProfileTabSystemDelegateDependencies
  = DownloadsManagerProviding
  & WindowSystemModelProviding

final class ProfileTabSystemDelegate: TabSystemDelegate {
  init(dependencies: ProfileTabSystemDelegateDependencies) {
    self.dependencies = dependencies
  }

  func newTabRequested(byTab: TabID, modifierFlags: Keystroke.ModifierFlags, completion: (TabSystemNewTabPolicy) -> Void) {
    if modifierFlags.contains(.shift) {
      completion(.continueWithGroup(TabGroupID.newSpace()))
    } else {
      withAnimation {
        completion(.continue)
      }
    }
  }
  
  func startDownload(_ webDownload: WebDownload, fromTab tabID: TabID) {
    dependencies.downloadsManager.startDownload(webDownload, forTab: tabID)
  }

  func didSelectTab(atIndex: Int?, previousIndex: Int?) {
    // Tweak the current animation based on frequency, distance traversed, etc.
    if CoreScheduler.currentAnimation != nil {
      CoreScheduler.currentAnimation = animationForSelectTab(atIndex: atIndex, previousIndex: previousIndex)
    }
  }

  private let dependencies: ProfileTabSystemDelegateDependencies
  private var timeSinceLastSelectTabCommand: ContinuousClock.Instant?

  private func animationForSelectTab(atIndex: Int?, previousIndex: Int?) -> CoreViewAnimation? {
    let now = ContinuousClock.now
    defer {
      timeSinceLastSelectTabCommand = now
    }
    if let timeSinceLastSelectTabCommand, now - timeSinceLastSelectTabCommand < .milliseconds(50) {
      return nil
    }

    let perceivedDuration: TimeInterval = 0.2

    guard let atIndex, let previousIndex else {
      return .easeOut(duration: perceivedDuration)
    }

    let numTabsTraversed = abs(atIndex - previousIndex)
    let maxTabsTraversed = 3

    let duration: TimeInterval
    let timeOffset: TimeInterval

    if numTabsTraversed <= maxTabsTraversed {
      duration = perceivedDuration
      timeOffset = 0
    } else {
      duration = perceivedDuration * Double(numTabsTraversed) / Double(maxTabsTraversed)
      timeOffset = Double(numTabsTraversed - maxTabsTraversed) * duration / Double(numTabsTraversed)
    }

    return .easeOut(duration: duration, timeOffset: timeOffset)
  }
}