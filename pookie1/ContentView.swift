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
            Tab("Overview", systemImage: "chart.bar.fill") {
                DashboardView()
            }
            Tab("Brain Health", systemImage: "brain.head.profile") {
                BrainHealthView()
            }
            Tab("Social", systemImage: "person.2.fill") {
                SocialView()
            }
            Tab("Apps", systemImage: "app.badge.checkmark") {
                AppSelectionView()
            }
        }
        .tint(BrainRotTheme.neonPink)
    }
}
