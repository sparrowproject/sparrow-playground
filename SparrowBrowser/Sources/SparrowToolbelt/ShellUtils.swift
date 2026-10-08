import Foundation

#if os(macOS)
import AppKit
#elseif os(Windows)
import WinSDK
#endif

public enum ShellUtils {
  public static func openFile(_ url: URL) {
    #if os(macOS)
    NSWorkspace.shared.open(url)
    #elseif os(Windows)
    shellExecuteOnWindows(operation: "open", file: shellPathOnWindows(for: url))
    #endif
  }

  public static func openFolder(_ url: URL) {
    #if os(macOS)
    NSWorkspace.shared.activateFileViewerSelecting([url])
    #elseif os(Windows)
    shellExecuteOnWindows(file: "explorer.exe", parameters: "/select,\"\(shellPathOnWindows(for: url))\"")
    #endif
  }
}

#if os(Windows)
private func shellPathOnWindows(for url: URL) -> String {
  var path = url.path(percentEncoded: false)

  if path.count >= 3,
    path[path.startIndex] == "/",
    path[path.index(path.startIndex, offsetBy: 2)] == ":"
  {
    path.removeFirst()
  }

  return path.replacingOccurrences(of: "/", with: "\\")
}

private func shellExecuteOnWindows(
  operation: String? = nil,
  file: String,
  parameters: String? = nil
) {
  let result = operation.withOptionalWideCString { operation in
    file.withCString(encodedAs: UTF16.self) { file in
      parameters.withOptionalWideCString { parameters in
        ShellExecuteW(nil, operation, file, parameters, nil, SW_SHOWNORMAL)
      }
    }
  }

  if Int(bitPattern: result) <= 32 {
    print(">>> ShellExecuteW failed: \(Int(bitPattern: result))")
  }
}

extension Optional where Wrapped == String {
  fileprivate func withOptionalWideCString<Result>(
    _ body: (UnsafePointer<WCHAR>?) throws -> Result
  ) rethrows -> Result {
    switch self {
    case .some(let string):
      try string.withCString(encodedAs: UTF16.self, body)
    case .none:
      try body(nil)
    }
  }
}
#endif
