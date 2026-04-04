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
    @State private var scrollToTopID = UUID()

    var body: some View {
        TabView(selection: tabBinding) {
            Tab(L("tab.shield"), systemImage: "shield.fill", value: "Shield") {
                BlockView()
            }
            Tab(L("tab.brainHealth"), systemImage: "chart.bar.fill", value: "BrainHealth") {
                BrainHealthView()
            }
            Tab(L("tab.overview"), systemImage: "brain.head.profile", value: "Overview") {
                DashboardView()
            }
            Tab(L("tab.settings"), systemImage: "gearshape.fill", value: "Settings") {
                SettingsView()
            }
        }
        .tint(BrainRotTheme.neonPink)
        .environment(\.scrollToTopID, scrollToTopID)
    }

    /// Custom binding that detects re-tapping the same tab
    private var tabBinding: Binding<String> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == selectedTab {
                    // Re-tapped same tab — trigger scroll to top
                    scrollToTopID = UUID()
                }
                selectedTab = newValue
            }
        )
    }
}

// MARK: - Scroll-to-top Environment Key

private struct ScrollToTopIDKey: EnvironmentKey {
    static let defaultValue = UUID()
}

extension EnvironmentValues {
    var scrollToTopID: UUID {
        get { self[ScrollToTopIDKey.self] }
        set { self[ScrollToTopIDKey.self] = newValue }
    }
}
