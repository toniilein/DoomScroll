import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct DashboardView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                if !screenTimeManager.isAuthorized {
                    ScrollView {
                        screenTimePrompt
                            .padding(.top)
                    }
                } else {
                    #if !targetEnvironment(simulator)
                    ZStack {
                        // Loading placeholder while extension processes
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(BrainRotTheme.neonPink)
                            Text(L("overview.loading"))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }

                        DeviceActivityReport(.totalActivity, filter: screenTimeManager.weekFilter(weekOffset: 0))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    #endif
                }
            }
            .navigationTitle(L("overview.title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Reset to today so Overview always opens on the current day
                let shared = UserDefaults(suiteName: "group.pookie1.shared")
                shared?.set(0, forKey: "selectedDayOffset")
                shared?.synchronize()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        generateAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(BrainRotTheme.neonPink)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Share

    @MainActor
    private func generateAndShare() {
        let score = SharedSettings.lastScore
        let streak = SharedSettings.streakDays
        let card = KrakenShareCardView(score: score, streakDays: streak)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true
        }
    }

    // MARK: - States

    private var screenTimePrompt: some View {
        VStack(spacing: 20) {
            Text("\u{1F9E0}")
                .font(.system(size: 60))

            Text("DoomScroll")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(BrainRotTheme.accentGradient)

            Text("Enable Screen Time access to track your doomscrolling")
                .font(.body)
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await screenTimeManager.requestAuthorization()
                }
            } label: {
                Text("Enable Screen Time")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BrainRotTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            if screenTimeManager.authorizationStatus == .denied {
                Text("Authorization denied. You may need the Family Controls entitlement \u{2014} check your Apple Developer account.")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.neonPink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - UIKit Share Sheet Wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
