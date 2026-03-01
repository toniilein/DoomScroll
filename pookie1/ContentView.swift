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
            Tab("Challenges", systemImage: "flag.checkered") {
                ChallengesView()
            }
            Tab("Brain Health", systemImage: "brain.head.profile") {
                BrainHealthView()
            }
            Tab("Overview", systemImage: "chart.bar.fill") {
                DashboardView()
            }
            Tab("Social", systemImage: "person.2.fill") {
                SocialView()
            }
            Tab("Apps", systemImage: "app.badge.checkmark") {
                AppSelectionView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(BrainRotTheme.neonPink)
    }
}
