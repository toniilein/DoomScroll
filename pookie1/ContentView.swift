import SwiftUI
#if !targetEnvironment(simulator)
import DeviceActivity
#endif

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
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedTab = "Overview"
    @State private var scrollToTopTrigger = UUID()

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
        .background {
            ZStack {
                // Invisible UIView that finds the UITabBar from the window and
                // installs a tap gesture to detect same-tab re-taps
                TabBarReselectionInstaller { scrollToTopTrigger = UUID() }
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)

                // Pre-warm the BrainHealth report extension so it's already
                // connected when the user navigates to that tab
                #if !targetEnvironment(simulator)
                if screenTimeManager.isAuthorized {
                    DeviceActivityReport(.brainHealth, filter: screenTimeManager.weeklyFilter())
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .allowsHitTesting(false)
                }
                #endif
            }
        }
    }
}

// MARK: - Tab Re-tap Detection (UIViewRepresentable — searches window for UITabBar)

/// Finds UITabBar by traversing the entire window view hierarchy (not the VC chain).
/// Adds a non-blocking tap gesture recognizer to detect same-tab re-taps.
struct TabBarReselectionInstaller: UIViewRepresentable {
    let onReselect: () -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.isHidden = true
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onReselect = onReselect
        if !context.coordinator.installed {
            // Try after a short delay to ensure view hierarchy is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                context.coordinator.install(from: uiView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onReselect: onReselect)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onReselect: () -> Void
        var installed = false
        private weak var tabBar: UITabBar?

        init(onReselect: @escaping () -> Void) {
            self.onReselect = onReselect
        }

        func install(from view: UIView) {
            guard !installed, let window = view.window else { return }
            guard let tabBar = Self.findTabBar(in: window) else {
                // Retry once more
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self, !self.installed, let window = view.window else { return }
                    if let tabBar = Self.findTabBar(in: window) {
                        self.addGesture(to: tabBar)
                    }
                }
                return
            }
            addGesture(to: tabBar)
        }

        private func addGesture(to tabBar: UITabBar) {
            guard !installed else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delegate = self  // Allow simultaneous recognition
            tabBar.addGestureRecognizer(tap)
            self.tabBar = tabBar
            installed = true
        }

        // Allow our gesture to work alongside the tab bar's built-in gestures
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let tabBar = gesture.view as? UITabBar,
                  let items = tabBar.items, !items.isEmpty,
                  let selectedItem = tabBar.selectedItem,
                  let selectedIdx = items.firstIndex(of: selectedItem) else { return }

            // Calculate which tab was tapped by location
            let loc = gesture.location(in: tabBar)
            let itemWidth = tabBar.bounds.width / CGFloat(items.count)
            let tappedIdx = min(max(0, Int(loc.x / itemWidth)), items.count - 1)

            if tappedIdx == selectedIdx {
                onReselect()
            }
        }

        static func findTabBar(in view: UIView) -> UITabBar? {
            if let tabBar = view as? UITabBar { return tabBar }
            for sub in view.subviews {
                if let found = findTabBar(in: sub) { return found }
            }
            return nil
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
