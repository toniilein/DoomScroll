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

// MARK: - Custom Tab Bar with Liquid Glass

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
        ZStack(alignment: .bottom) {
            // All tab content — always alive
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

            // Floating Liquid Glass tab bar
            GlassEffectContainer {
                ForEach(tabs) { tab in
                    Button {
                        if selectedTab == tab.id {
                            scrollToTopTrigger = UUID()
                        } else {
                            selectedTab = tab.id
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 21))
                                .symbolRenderingMode(.monochrome)
                                .frame(height: 24)
                            Text(L(tab.labelKey))
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(selectedTab == tab.id ? BrainRotTheme.neonPink : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .glassEffect(selectedTab == tab.id ? .regular : .clear, in: .capsule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 2)
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
