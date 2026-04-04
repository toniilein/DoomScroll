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

// MARK: - Tab Reselect Detection (UIViewControllerRepresentable — walks UP parent chain)

/// Embeds a tiny UIViewController inside a tab. It uses `self.tabBarController` (which walks UP
/// the parent VC chain) to find the UITabBarController and set a delegate to detect re-taps.
struct TabBarReselectionDetector: UIViewControllerRepresentable {
    let onReselect: () -> Void

    func makeUIViewController(context: Context) -> ReselectionVC {
        ReselectionVC(coordinator: context.coordinator)
    }

    func updateUIViewController(_ vc: ReselectionVC, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onReselect: onReselect) }

    class Coordinator: NSObject, UITabBarControllerDelegate {
        let onReselect: () -> Void
        init(onReselect: @escaping () -> Void) { self.onReselect = onReselect }

        func tabBarController(_ tbc: UITabBarController, shouldSelect vc: UIViewController) -> Bool {
            if vc == tbc.selectedViewController {
                onReselect()
            }
            return true
        }
    }

    class ReselectionVC: UIViewController {
        private weak var coordinator: Coordinator?

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            findAndSetDelegate()
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            findAndSetDelegate()
        }

        private func findAndSetDelegate() {
            // self.tabBarController walks UP the parent VC chain — much more reliable
            if let tbc = self.tabBarController {
                tbc.delegate = coordinator
                return
            }
            // Fallback: try again shortly (SwiftUI may not have finished embedding yet)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                if let tbc = self?.tabBarController {
                    tbc.delegate = self?.coordinator
                }
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
