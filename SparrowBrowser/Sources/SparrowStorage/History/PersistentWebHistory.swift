import Foundation
import SparrowStorageBase
import SparrowToolbelt
import SparrowUIFoundation
import SparrowWeb

public typealias PersistentWebHistoryDependencies
  = StoragePathsProviding

extension Factory where Interface == WebHistory {
  public static func makePersistentInstance(dependencies: PersistentWebHistoryDependencies) -> WebHistory {
    // Avoid repeated storage reads and share image loading with consumers.
    CachingWebHistory(source: PersistentWebHistory(dependencies: dependencies))
  }
}

final class PersistentWebHistory: WebHistory {
  init(dependencies: PersistentWebHistoryDependencies) {
    self.dependencies = dependencies

    faviconURLStore = .init(directory: dependencies.faviconURLStoragePath)
    faviconImageStore = .init(directory: dependencies.faviconImageStoragePath)
  }

  func storeFaviconURL(_ faviconURL: URL, forPageURL pageURL: URL, withColorScheme colorScheme: ColorScheme) {
    guard !isShuttingDown else { return }
    let key = FaviconURLKey(pageURL: pageURL, colorScheme: colorScheme)
    faviconURLStore.write(faviconURL, forKey: key.rawValue, codec: .json)
  }

  func queryFaviconURL(forPageURL pageURL: URL, withColorScheme colorScheme: ColorScheme) async -> URL? {
    guard !isShuttingDown else { return nil }
    let key = FaviconURLKey(pageURL: pageURL, colorScheme: colorScheme)
    do {
      return try await faviconURLStore.read(forKey: key.rawValue, codec: .json)
    } catch {
      print(">>> Error reading from favicon URL store: \(error)")
      return nil
    }
  }

  func storeImage(_ imageProvider: AnyImageProvider, forFaviconURL faviconURL: URL) {
    guard !isShuttingDown else { return }
    let previous = pendingFaviconImageWrites[faviconURL]
    let id = UUID()
    let task = Task {
      // Preserve call order even when providers resolve at different speeds.
      await previous?.task.value
      defer {
        if pendingFaviconImageWrites[faviconURL]?.id == id {
          pendingFaviconImageWrites.removeValue(forKey: faviconURL)
        }
      }

      guard let image = await imageProvider.getImage() else { return }
      guard let imageData = await ImageCodecs.lossless.encode(image) else {
        print(">>> image encoding failed!")
        return
      }
      faviconImageStore.write(imageData, forKey: faviconURL.absoluteString)
    }
    pendingFaviconImageWrites[faviconURL] = PendingImageWrite(id: id, task: task)
  }

  func queryImage(forFaviconURL faviconURL: URL) async -> AnyImageProvider? {
    guard !isShuttingDown else { return nil }
    // A newer write can arrive while this method is suspended. Wait until all
    // writes for this key have enqueued their bytes before enqueueing the read.
    while let pending = pendingFaviconImageWrites[faviconURL] {
      await pending.task.value
      guard !isShuttingDown else { return nil }
    }
    do {
      guard let data = try await faviconImageStore.read(forKey: faviconURL.absoluteString) else {
        return nil
      }
      return CachingImageProvider(
        source: DecodingImageProvider(data: data, codec: ImageCodecs.lossless),
      )
    } catch {
      print(">>> Error reading from favicon image store: \(error)")
      return nil
    }
  }

  private struct FaviconURLKey: RawRepresentable {
    init(pageURL: URL, colorScheme: ColorScheme) {
      self.pageURL = pageURL
      self.colorScheme = colorScheme
    }

    init?(rawValue: String) {
      let components = rawValue.split(separator: ":", maxSplits: 1)
      guard
        components.count == 2,
        let colorScheme = ColorScheme(rawValue: String(components[0])),
        let pageURL = URL(string: String(components[1]))
      else {
        return nil
      }
      self.init(pageURL: pageURL, colorScheme: colorScheme)
    }

    let pageURL: URL
    let colorScheme: ColorScheme

    var rawValue: String {
      "\(colorScheme.rawValue):\(pageURL.absoluteString)"
    }
  }

  private let dependencies: PersistentWebHistoryDependencies
  private let faviconURLStore: BlobStore
  private let faviconImageStore: BlobStore
  private struct PendingImageWrite {
    let id: UUID
    let task: Task<Void, Never>
  }
  private var pendingFaviconImageWrites = [URL: PendingImageWrite]()
  private var isShuttingDown = false
  private var shutdownTask: Task<Void, Never>?
}

extension PersistentWebHistory: StorageComponent {
  func shutdown() -> Task<Void, Never>? {
    guard !isShuttingDown else { return shutdownTask }
    isShuttingDown = true
    func closeAll() {
      do {
        try faviconURLStore.close()
      } catch {
        print(">>> Error closing favicon URL store: \(error)")
      }
      do {
        try faviconImageStore.close()
      } catch {
        print(">>> Error closing favicon image store: \(error)")
      }
    }

    if pendingFaviconImageWrites.isEmpty {
      closeAll()
      return nil
    }

    let pending = Array(pendingFaviconImageWrites.values)
    let task = Task {
      for write in pending {
        await write.task.value
      }
      closeAll()
    }
    shutdownTask = task
    return task
  }
}

extension PersistentWebHistoryDependencies {
  @MainActor
  var faviconURLStoragePath: URL {
    storagePaths.userDataDirectory.appendingPathComponent("favicon-urls")
  }

  @MainActor
  var faviconImageStoragePath: URL {
    storagePaths.userDataDirectory.appendingPathComponent("favicon-images")
  }
}
