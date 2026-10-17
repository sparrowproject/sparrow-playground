import SparrowDownloads
import SparrowSpaces
import SparrowTabs
import SparrowToolbelt
import SparrowUIFoundation
import SparrowWeb

typealias ProfileTabSystemDelegateDependencies
  = DownloadsManagerProviding

final class ProfileTabSystemDelegate: TabSystemDelegate {
  init(dependencies: ProfileTabSystemDelegateDependencies) {
    self.dependencies = dependencies
  }

  func newTabRequested(byTab: TabID, modifierFlags: Keystroke.ModifierFlags) -> TabSystemNewTabPolicy {
    if modifierFlags.contains(.shift) {
      // let groupID = TabGroupID.newSpace()
      // // Call the completion to populate the new space.
      // completion(.continueWithGroup(groupID))
      // createBrowserWindow(forGroup: groupID, inProfile: profileID)
      .continueWithGroup(TabGroupID.newSpace())
    } else {
      .continue
    }
  }
  
  func startDownload(_ webDownload: WebDownload, fromTab tabID: TabID) {
    dependencies.downloadsManager.startDownload(webDownload, forTab: tabID)
  }

  private let dependencies: ProfileTabSystemDelegateDependencies
}


  // private func handleTabSystemAction(_ action: TabSystemAction, for profileID: ProfileID) {
  //   switch action {
  //   case .newTabRequested(_, let modifierFlags, let completion):
  //     print(">>> newTabRequested w/ modifierFlags: \(modifierFlags)")
  //     if modifierFlags.contains(.shift) {
  //       let groupID = TabGroupID.newSpace()
  //       // Call the completion to populate the new space.
  //       completion(.continueWithGroup(groupID))
  //       createBrowserWindow(forGroup: groupID, inProfile: profileID)
  //     } else {
  //       withAnimation {
  //         completion(.continue)
  //       }
  //     }
  //   case .startDownload(let webDownload, let tabID):
  //     print(">>> handling .startDownload")
  //     dependencies.profileSystem.container(for: profileID).downloadsManager.startDownload(
  //       webDownload, forTab: tabID
  //     )
  //   }
  // }
