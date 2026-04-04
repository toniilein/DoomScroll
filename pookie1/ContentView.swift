import SwiftUI
import Combine

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
    @State private var scrollToTopTrigger = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(L("tab.shield"), systemImage: "shield.fill", value: "Shield") {
                BlockView()
                    .background(
                        TabBarReselectionDetector { scrollToTopTrigger = UUID() }
                            .frame(width: 0, height: 0)
                    )
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
    }
}

// MARK: - Tab Reselect Detection via UITabBar gesture recognizer
// Does NOT replace the UITabBarController delegate (which SwiftUI needs).
// Instead, adds a tap gesture recognizer to the UITabBar to detect re-taps.

struct TabBarReselectionDetector: UIViewControllerRepresentable {
    let onReselect: () -> Void

    func makeUIViewController(context: Context) -> ReselectionVC {
        ReselectionVC(onReselect: onReselect)
    }

    func updateUIViewController(_ vc: ReselectionVC, context: Context) {
        vc.onReselect = onReselect
    }

    func makeCoordinator() -> Void { () }

    class ReselectionVC: UIViewController {
        var onReselect: () -> Void
        private var tapRecognizer: UITapGestureRecognizer?

        init(onReselect: @escaping () -> Void) {
            self.onReselect = onReselect
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installGestureRecognizer()
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            installGestureRecognizer()
        }

        private func installGestureRecognizer() {
            guard tapRecognizer == nil else { return }
            guard let tbc = self.tabBarController else {
                // Retry shortly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.installGestureRecognizer()
                }
                return
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTabBarTap(_:)))
            tap.cancelsTouchesInView = false  // Don't block normal tab selection
            tbc.tabBar.addGestureRecognizer(tap)
            tapRecognizer = tap
        }

        @objc private func handleTabBarTap(_ recognizer: UITapGestureRecognizer) {
            guard let tbc = self.tabBarController,
                  let items = tbc.tabBar.items,
                  !items.isEmpty else { return }

            let location = recognizer.location(in: tbc.tabBar)
            let tabBar = tbc.tabBar
            let itemWidth = tabBar.bounds.width / CGFloat(items.count)
            let tappedIndex = min(Int(location.x / itemWidth), items.count - 1)

            if tappedIndex == tbc.selectedIndex {
                // Same tab re-tapped — scroll to top
                onReselect()
            }
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
