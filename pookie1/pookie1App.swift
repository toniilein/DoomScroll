import SwiftUI

@main
struct pookie1App: App {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenTimeManager)
        }
    }
}
