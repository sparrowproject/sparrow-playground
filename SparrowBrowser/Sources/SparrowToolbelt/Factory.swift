// Specialize this type to provide factory methods for a particular interface.
//
// Example:
// ```
//   extension Factory where Interface == WindowManager {
//     public static func makeDefaultInstance() -> WindowManager {
//       DefaultWindowManager()
//     }
//   }
// ```
@MainActor
public struct Factory<Interface> {}

