import SwiftUI

struct ContentView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    private var themeManager = ThemeManager.shared

    var body: some View {
        Group {
            if screenTimeManager.isAuthorized {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

// MARK: - Native TabView (Liquid Glass automatic on iOS 26)

struct MainTabView: View {
    @State private var selectedTab = "Overview"
    @State private var scrollToTopTrigger = UUID()
    @State private var preloaded = false

    var body: some View {
        TabView(selection: $selectedTab) {
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
        .environment(\.scrollToTopTrigger, scrollToTopTrigger)
        .task {
            // Pre-load all tabs by briefly cycling through them so
            // DeviceActivityReport extensions connect on launch.
            // Fixes BrainHealth blank screen on first visit.
            guard !preloaded else { return }
            preloaded = true
            try? await Task.sleep(for: .milliseconds(100))
            for tab in ["Shield", "BrainHealth", "Settings"] {
                selectedTab = tab
                try? await Task.sleep(for: .milliseconds(150))
            }
            selectedTab = "Overview"
        }
    }
}

// MARK: - Scroll-to-top Environment Key

private struct ScrollToTopTriggerKey: EnvironmentKey {
    static let defaultValue = UUID()
}

extension EnvironmentValues {
    var scrollToTopTrigger: UUID {
        get { self[ScrollToTopTriggerKey.self] }
        set { self[ScrollToTopTriggerKey.self] = newValue }
    }
}
