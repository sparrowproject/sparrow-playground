import Foundation
import SparrowStorageBase

final class ProfileStoragePaths: StoragePaths {
  init(index: Int, rootPaths: StoragePaths) {
    self.index = index
    self.rootPaths = rootPaths
  }

  private(set) lazy var userDataDirectory: URL = {
    let rootUserDataDirectory = rootPaths.userDataDirectory

    let dataURL = rootUserDataDirectory
      .appendingPathComponent("\(index)", isDirectory: true)

    try! FileManager.default.createDirectory(
      at: dataURL,
      withIntermediateDirectories: true
    )

    return dataURL
  }()

  private let index: Int
  private let rootPaths: StoragePaths
}