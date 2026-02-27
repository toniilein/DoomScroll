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
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("⚠️ GoogleService-Info.plist not found — Firebase disabled. Download it from https://console.firebase.google.com/")
        }
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
