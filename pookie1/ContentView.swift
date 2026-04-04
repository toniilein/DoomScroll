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
    @StateObject private var tabReselect = TabReselectObserver()

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
        .onAppear { tabReselect.setup() }
        .environment(\.scrollToTopTrigger, tabReselect.scrollTrigger)
    }
}

// MARK: - Tab Reselect Observer (UIKit introspection)

/// Listens for UITabBarController delegate calls to detect re-selecting the current tab
class TabReselectObserver: NSObject, ObservableObject, UITabBarControllerDelegate {
    @Published var scrollTrigger = UUID()
    private weak var tabBarController: UITabBarController?

    func setup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            if let tbc = self.findTabBarController() {
                self.tabBarController = tbc
                tbc.delegate = self
            }
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController == tabBarController.selectedViewController {
            // Same tab re-tapped — trigger scroll to top
            scrollTrigger = UUID()
        }
        return true
    }

    private func findTabBarController() -> UITabBarController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else { return nil }
        return findTBC(in: root)
    }

    private func findTBC(in vc: UIViewController) -> UITabBarController? {
        if let tbc = vc as? UITabBarController { return tbc }
        for child in vc.children {
            if let found = findTBC(in: child) { return found }
        }
        if let presented = vc.presentedViewController {
            return findTBC(in: presented)
        }
        return nil
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
