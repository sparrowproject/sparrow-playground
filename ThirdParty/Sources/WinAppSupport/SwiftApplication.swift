import Foundation
import WinAppSDK
import WinSDK
@_spi(WinRTInternal) import WinUI
@_spi(WinRTImplements) import WindowsFoundation

/// You should derive from SwiftApplication and mark this class as your @main entry point. This class
/// will ensure that the Windows Runtime is properly initialized and that your WinUI Application
/// is properly configured.
///
/// Example usage:
/// ```
/// import WinUI
///
/// @main
/// class MySwiftApp: SwiftApplication {
///   required init() {
///     super.init()
///   }
///
///  override func onLaunched(_ args: LaunchActivatedEventArgs) {
///    let window = Window()
///    window.content = TextBlock(text: "Hello, world!")
///    window.activate()
///   }
/// ```
open class SwiftApplication: Application, IXamlMetadataProvider {
    public typealias RunLoop = (DispatcherQueue) throws -> Int32

    public required override init() {
        super.init()
    }

    @_spi(WinRTImplements)
    override public func onLaunched(_ args: LaunchActivatedEventArgs?) {
        resources.mergedDictionaries.append(XamlControlsResources())
        onLaunched(args!)
    }

    /// If you've setup your project to be self-contained WinAppSDK
    open class var windowsAppSdkSelfContained: Bool { false }

    /// If you own your own run loop and don't want to use the WinUI one, override it here
    open class var runLoop: RunLoop { Self.defaultRunLoop }

    /// Override this method to provide your application's main entry point.
    /// The first window for your application should be created and activated here.
    open func onLaunched(_ args: LaunchActivatedEventArgs) {
    }

    private typealias pfnContentPreTranslateMessage = @convention(c) (UnsafePointer<MSG>?) -> Bool
    private static let contentPreTranslateMessage: pfnContentPreTranslateMessage = {
        let windowingDLL = LoadLibraryA("Microsoft.UI.Windowing.Core.dll")
        let contentPreTranslateMessage = GetProcAddress(windowingDLL, "ContentPreTranslateMessage")
        return unsafeBitCast(contentPreTranslateMessage!, to: pfnContentPreTranslateMessage.self)
    }()

    private static func defaultRunLoop(_ queue: DispatcherQueue) -> Int32 {
        // The below run loop is taken mostly from https://github.com/compnerd/swift-win32/blob/d34ff1b8b3f15cfdf2cb71109a3c313001122a54/Sources/SwiftWin32/App%20and%20Environment/ApplicationMain.swift#L183
        // with some tweaks for WinUI
        var msg: MSG = MSG()
        while true {

            // Process all messages in thread's message queue; for GUI applications UI
            // events must have high priority.
            while PeekMessageW(&msg, nil, 0, 0, UINT(PM_REMOVE)) {
                if msg.message == UINT(WM_QUIT) {
                    return Int32(msg.wParam)
                }

                if (!contentPreTranslateMessage(&msg)) {
                    TranslateMessage(&msg)
                    DispatchMessageW(&msg)
                }
            }

            var time: Date? = nil
            repeat {
            // Execute Foundation.RunLoop once and determine the next time the timer
            // fires.  At this point handle all Foundation.RunLoop timers, sources and
            // Dispatch.DispatchQueue.main tasks
            time = Foundation.RunLoop.main.limitDate(forMode: .default)

            // If Foundation.RunLoop doesn't contain any timers or the timers should
            // not be running right now, we interrupt the current loop or otherwise
            // continue to the next iteration.
            } while (time?.timeIntervalSinceNow ?? -1) <= 0

            // Yield control to the system until the earlier of a requisite timer
            // expiration or a message is posted to the runloop.
            _ = MsgWaitForMultipleObjects(0, nil, false,
                                        DWORD(exactly: time?.timeIntervalSinceNow ?? -1)
                                            ?? 0,
                                        QS_ALLINPUT)
        }
        return 0
    }

    /// Override this method to provide any necessary shutdown code.
    open func onShutdown(exitCode: Int32) { }
    
    public static func main() {
        do {
            let appClass = String(describing: String(reflecting: Self.self))
            guard let instance = NSClassFromString(appClass) as? SwiftApplication.Type else {
                fatalError("unable to find application class \(appClass)")
            }

            try withExtendedLifetime(WindowsAppRuntimeInitializer(selfContained: instance.windowsAppSdkSelfContained)) {
                var application: SwiftApplication!
                let createAppCallback: (ApplicationInitializationCallbackParams?) -> Void = { _ in
                    application = instance.init()
                }
                let exitCode = try Application.startWithCustomRunLoop(instance.runLoop, createAppCallback)
              
                application.onShutdown(exitCode: exitCode)
            }
        }
        catch {
            fatalError("Failed to initialize WindowsAppRuntimeInitializer: \(error)")
        }
    }

    override open func queryInterface(_ iid: WindowsFoundation.IID) -> IUnknownRef? {
        switch iid {
        case __ABI_Microsoft_UI_Xaml_Markup.IXamlMetadataProviderWrapper.IID:
            let ixmp = __ABI_Microsoft_UI_Xaml_Markup.IXamlMetadataProviderWrapper(self)
            return ixmp?.queryInterface(iid)
        default:
            return super.queryInterface(iid)
        }
    }

    private lazy var metadataProvider: XamlControlsXamlMetaDataProvider = .init()
    public func getXamlType(_ type: TypeName) throws -> IXamlType! {
        try metadataProvider.getXamlType(type)
    }

    public func getXamlType(_ fullName: String) throws -> IXamlType! {
        try metadataProvider.getXamlType(fullName)
    }

    public func getXmlnsDefinitions() throws -> [XmlnsDefinition] {
        try metadataProvider.getXmlnsDefinitions()
    }
}
