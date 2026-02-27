import SwiftUI
#if !targetEnvironment(simulator)
import FirebaseCore
#endif

@main
struct pookie1App: App {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var firebaseManager = FirebaseManager.shared

    init() {
        #if !targetEnvironment(simulator)
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenTimeManager)
                .environmentObject(firebaseManager)
        }
    }
}
