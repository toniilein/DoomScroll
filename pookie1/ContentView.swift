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

// MARK: - Custom Tab Bar (replaces SwiftUI TabView for re-tap detection)

struct MainTabView: View {
    @State private var selectedTab = "Overview"
    @State private var scrollToTopTrigger = UUID()

    private struct TabItem: Identifiable {
        let id: String
        let icon: String
        let labelKey: String
    }

    private let tabs: [TabItem] = [
        TabItem(id: "Shield", icon: "shield.fill", labelKey: "tab.shield"),
        TabItem(id: "BrainHealth", icon: "chart.bar.fill", labelKey: "tab.brainHealth"),
        TabItem(id: "Overview", icon: "brain.head.profile", labelKey: "tab.overview"),
        TabItem(id: "Settings", icon: "gearshape.fill", labelKey: "tab.settings"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // All tab content views are always alive — prevents BrainHealth first-render issue
            ZStack {
                BlockView()
                    .opacity(selectedTab == "Shield" ? 1 : 0)
                    .allowsHitTesting(selectedTab == "Shield")

                BrainHealthView()
                    .opacity(selectedTab == "BrainHealth" ? 1 : 0)
                    .allowsHitTesting(selectedTab == "BrainHealth")

                DashboardView()
                    .opacity(selectedTab == "Overview" ? 1 : 0)
                    .allowsHitTesting(selectedTab == "Overview")

                SettingsView()
                    .opacity(selectedTab == "Settings" ? 1 : 0)
                    .allowsHitTesting(selectedTab == "Settings")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        Button {
                            if selectedTab == tab.id {
                                // Re-tap — scroll to top
                                scrollToTopTrigger = UUID()
                            } else {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedTab = tab.id
                                }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 22))
                                    .frame(height: 24)
                                Text(L(tab.labelKey))
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(selectedTab == tab.id ? BrainRotTheme.neonPink : Color(.systemGray))
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            .background {
                Rectangle()
                    .fill(.bar)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .environment(\.scrollToTopTrigger, scrollToTopTrigger)
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
