import Foundation
import SparrowToolbelt

@MainActor
public protocol StoragePaths {
  var userDataDirectory: URL { get }
}

public protocol StoragePathsProviding {
  @MainActor
  var storagePaths: StoragePaths { get }
}

extension Factory where Interface == StoragePaths {
  public static func makeRootInstance() -> StoragePaths {
    RootStoragePaths()
  }
}

final class RootStoragePaths: StoragePaths {
  init() {}

  private(set) lazy var userDataDirectory: URL = {
    let appSupportURL = try! FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )

    #if DEBUG
    let identifier = "SparrowBrowser-Debug"
    #else
    let identifier = "SparrowBrowser"
    #endif
    let dataURL = appSupportURL
      .appendingPathComponent(identifier, isDirectory: true)

    try! FileManager.default.createDirectory(
      at: dataURL,
      withIntermediateDirectories: true
    )

    return dataURL
  }()
}