import Dispatch
import Foundation
import WinAppSDK
import WinSDK
import WinUI

import CWinAppSDK

extension Application {
    /// same as WinUI.Application.start, but with RunLoop and Dispatch support.
    /// - Parameter handler: initialize the Application in this handler
    /// - Parameter runLoop: this is called once the Application is initialized, and is responsible for running the RunLoop
    public static func startWithCustomRunLoop(_ runLoop: SwiftApplication.RunLoop,
        _ handler: @MainActor (ApplicationInitializationCallbackParams?) -> Void
    ) throws -> Int32 {
        try MainActor.assumeIsolated {
            // setUpUWPDispatcherQueueController()
            SetUpLegacyDispatcherQueueController()

            // A DispatcherQueue must exist on the thread before initializing WindowsXamlManager
            // We create a dispatcherQueueController to create and manage the DispatcherQueue
            let dispatcherQueueController: DispatcherQueueController = try DispatcherQueueController.createOnCurrentThread()

            handler(nil)

            guard let application = Application.current else {
                fatalError("Application not created in callback")
            }

            let xamlManager: WindowsXamlManager = try WindowsXamlManager.initializeForCurrentThread()
            application.dispatcherShutdownMode = .onLastWindowClose
            return try withExtendedLifetime([xamlManager, dispatcherQueueController, application]) {
                try runLoop(dispatcherQueueController.dispatcherQueue)
            }
        }
    }
}

// import CWinRT

// private func setUpUWPDispatcherQueueController() {
//     var options = DispatcherQueueOptions(
//         dwSize: UInt32(MemoryLayout<DispatcherQueueOptions>.size),
//         threadType: DQTYPE_THREAD_CURRENT,
//         apartmentType: DQTAT_COM_STA
//     )

//     var controller: UnsafeMutablePointer<IDispatcherQueueController>?

//     let hr = CreateDispatcherQueueController(
//         options,
//         &controller
//     )

//     guard hr == S_OK else {
//         fatalError("CreateDispatcherQueueController failed: \(hr)")
//     }
// }