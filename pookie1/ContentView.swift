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
        .preferredColorScheme(.light)
    }
}

struct MainTabView: View {
    @State private var selectedTab = "Overview"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Shield", systemImage: "shield.fill", value: "Shield") {
                BlockView()
            }
            Tab("Brain Health", systemImage: "chart.bar.fill", value: "BrainHealth") {
                BrainHealthView()
            }
            Tab("Overview", systemImage: "brain.head.profile", value: "Overview") {
                DashboardView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: "Settings") {
                SettingsView()
            }
        }
        .tint(BrainRotTheme.neonPink)
    }
}
