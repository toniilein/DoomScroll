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

// MARK: - Hybrid Tab View
// Native TabView provides the Liquid Glass tab bar.
// Content lives in a ZStack behind it (always alive — fixes BrainHealth first-render).
// TabView content is Color.clear with hit-testing disabled so touches pass through.

struct MainTabView: View {
    @State private var selectedTab = "Overview"
    @State private var scrollToTopTrigger = UUID()

    var body: some View {
        ZStack {
            // Real content — all views always alive in ZStack
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

            // Native TabView — only provides the Liquid Glass tab bar
            TabView(selection: $selectedTab) {
                Tab(L("tab.shield"), systemImage: "shield.fill", value: "Shield") {
                    Color.clear.allowsHitTesting(false)
                }
                Tab(L("tab.brainHealth"), systemImage: "chart.bar.fill", value: "BrainHealth") {
                    Color.clear.allowsHitTesting(false)
                }
                Tab(L("tab.overview"), systemImage: "brain.head.profile", value: "Overview") {
                    Color.clear.allowsHitTesting(false)
                }
                Tab(L("tab.settings"), systemImage: "gearshape.fill", value: "Settings") {
                    Color.clear.allowsHitTesting(false)
                }
            }
            .tint(BrainRotTheme.neonPink)
        }
        .environment(\.scrollToTopTrigger, scrollToTopTrigger)
        .background(
            // UIView-based tap detector for scroll-to-top on tab re-tap
            TabBarReselectionInstaller { scrollToTopTrigger = UUID() }
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Tab Re-tap Detection (UIViewRepresentable — searches window for UITabBar)

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

        init(onReselect: @escaping () -> Void) {
            self.onReselect = onReselect
        }

        func install(from view: UIView) {
            guard !installed, let window = view.window else { return }
            guard let tabBar = Self.findTabBar(in: window) else {
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
            tap.delegate = self
            tabBar.addGestureRecognizer(tap)
            installed = true
        }

        func gestureRecognizer(_ gr: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let tabBar = gesture.view as? UITabBar,
                  let items = tabBar.items, !items.isEmpty,
                  let selectedItem = tabBar.selectedItem,
                  let selectedIdx = items.firstIndex(of: selectedItem) else { return }

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
