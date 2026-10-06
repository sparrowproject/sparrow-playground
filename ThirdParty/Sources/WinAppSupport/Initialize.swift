import CWinRT
import CWinAppSDK
import Foundation
import WindowsFoundation
import WinSDK

public enum ThreadingModel {
    case single
    case multi
}

/// WindowsAppRuntimeInitializer is used to properly initialize the Windows App SDK runtime, along with the Windows Runtime.
/// The runtime is initalized for the lifetime of the object, and is deinitialized when the object is deallocated.
/// Example usage:
/// ```
/// public static func main() {
///        do {
///            try withExtendedLifetime(WindowsAppRuntimeInitializer()) {
///                initialization code here
///            }
///        }
///        catch {
///            fatalError("Failed to initialize WindowsAppRuntimeInitializer: \(error)")
///        }
///    }
/// ```
public class WindowsAppRuntimeInitializer {
    // TODO: Figure out how to properly link against delayimp.lib so that we can delay load the bootstrap dll.
    private typealias pfnMddBootstrapInitialize2 = @convention(c) (UInt32, PCWSTR?, PACKAGE_VERSION, MddBootstrapInitializeOptions) -> HRESULT
    private typealias pfnMddBootstrapShutdown = @convention(c) () -> Void
    private lazy var bootstrapperDll: HMODULE = {
        guard let url = Bundle.main.url(
            forResource: "Microsoft.WindowsAppRuntime.Bootstrap",
            withExtension: ".dll") else {    
            preconditionFailure("Microsoft.WindowsAppRuntime.Bootstrap.dll not found!")
        }
        let path = url.withUnsafeFileSystemRepresentation { String(cString: $0!) }
        guard let module = path.withCString(encodedAs: UTF16.self, LoadLibraryW) else {
            preconditionFailure("Failed to load Microsoft.WindowsAppRuntime.Bootstrap.dll")
        }
        return module
    }()

    private lazy var Initialize: pfnMddBootstrapInitialize2 = {
        let pfn = GetProcAddress(bootstrapperDll, "MddBootstrapInitialize2")
        return unsafeBitCast(pfn, to: pfnMddBootstrapInitialize2.self)
    }()

    private lazy var Shutdown: pfnMddBootstrapShutdown = {
        let pfn = GetProcAddress(bootstrapperDll, "MddBootstrapShutdown")
        return unsafeBitCast(pfn, to: pfnMddBootstrapShutdown.self)
    }()

    private func processHasIdentity() -> Bool {
        var length: UInt32 = 0
        return GetCurrentPackageFullName(&length, nil) != APPMODEL_ERROR_NO_PACKAGE
    }

    private let selfContained: Bool

    private lazy var initWinAppSDK: Bool = {
        !processHasIdentity() && !selfContained
    }()

    public init(threadingModel: ThreadingModel = .single, selfContained: Bool = false) throws  {
        self.selfContained = selfContained
        let roInitParam = switch threadingModel {
            case .single: RO_INIT_SINGLETHREADED
            case .multi: RO_INIT_MULTITHREADED
        }

        try CHECKED(RoInitialize(roInitParam))

        guard initWinAppSDK else {
            return
        }

        let ver = String(decoding: UnsafeBufferPointer(start: WINDOWSAPPSDK_RELEASE_VERSION_TAG_SWIFT, count: wcslen(WINDOWSAPPSDK_RELEASE_VERSION_TAG_SWIFT)), as: UTF16.self)

        print("initialize: \(ver)")

        var minVersion = PACKAGE_VERSION()
        minVersion.Version = WINDOWSAPPSDK_RUNTIME_VERSION_UINT64

        let hr = Initialize(
            UInt32(WINDOWSAPPSDK_RELEASE_MAJORMINOR),
            WINDOWSAPPSDK_RELEASE_VERSION_TAG_SWIFT,
            minVersion,
            MddBootstrapInitializeOptions(
                MddBootstrapInitializeOptions_OnNoMatch_ShowUI.rawValue
            )
        )
        let tracePackageGraph = ProcessInfo.processInfo.environment["WINAPPSUPPORT_TRACE_PACKAGE_GRAPH"] != nil
        if tracePackageGraph {
            print(String(format: "MddBootstrapInitialize2: 0x%08X", UInt32(bitPattern: hr)))
        }
        try CHECKED(hr)
        if tracePackageGraph {
            PrintCurrentPackageGraph()
            PrintWinAppRuntimeModulePaths()
        }
    }

    deinit {
        RoUninitialize()    
        if initWinAppSDK {
            Shutdown()
        }
        FreeLibrary(bootstrapperDll)
    }
}
