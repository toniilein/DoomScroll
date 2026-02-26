import SwiftUI

struct ContentView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        Group {
            if screenTimeManager.isAuthorized {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "brain.head.profile") {
                DashboardView()
            }
            Tab("Apps", systemImage: "app.badge.checkmark") {
                AppSelectionView()
            }
        }
        .tint(BrainRotTheme.neonPink)
    }
}
