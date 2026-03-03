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
            Tab("Challenges", systemImage: "flag.checkered", value: "Challenges") {
                ChallengesView()
            }
            Tab("Overview", systemImage: "chart.bar.fill", value: "BrainHealth") {
                BrainHealthView()
            }
            Tab("Brain Health", systemImage: "brain.head.profile", value: "Overview") {
                DashboardView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: "Settings") {
                SettingsView()
            }
        }
        .tint(BrainRotTheme.neonPink)
    }
}
