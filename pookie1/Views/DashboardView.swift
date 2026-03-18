import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct DashboardView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedDayOffset = 0 // 0 = today, -1 = yesterday, etc.
    @State private var weekOffset = 0 // 0 = current week, -1 = last week, etc.
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var pollTimer: Timer?

    private let shared = UserDefaults(suiteName: "group.pookie1.shared")

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDayOffset, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }

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
                    VStack(spacing: 0) {
                        weekDaySelector
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                        #if !targetEnvironment(simulator)
                        DeviceActivityReport(.totalActivity, filter: screenTimeManager.filterForDate(selectedDate))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif
                    }
                }
            }
            .navigationTitle("Overview")
            .toolbarColorScheme(.light, for: .navigationBar)
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
            .onAppear {
                // Write current week offset so extension knows which week to render
                shared?.set(weekOffset, forKey: "dayPillsWeekOffset")
                shared?.set(selectedDayOffset, forKey: "selectedDayOffset")
                shared?.synchronize()
                startPolling()
            }
            .onDisappear {
                pollTimer?.invalidate()
                pollTimer = nil
            }
            .onChange(of: weekOffset) { _, newValue in
                shared?.set(newValue, forKey: "dayPillsWeekOffset")
                shared?.synchronize()
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Polling for selection changes from extension

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            shared?.synchronize()
            let extOffset = shared?.integer(forKey: "selectedDayOffset") ?? 0
            if extOffset != selectedDayOffset {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDayOffset = extOffset
                    }
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

    // MARK: - Week Day Selector

    private var weekDaySelector: some View {
        VStack(spacing: 6) {
            // Week navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        weekOffset -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(BrainRotTheme.textSecondary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(weekLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        weekOffset += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(weekOffset < 0 ? BrainRotTheme.textSecondary : BrainRotTheme.textSecondary.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                .disabled(weekOffset >= 0)
            }

            // Day pills rendered by the extension (with correct octopus colors)
            #if !targetEnvironment(simulator)
            DeviceActivityReport(.dayPills, filter: screenTimeManager.weekFilter(weekOffset: weekOffset))
                .frame(height: 80)
            #endif
        }
    }

    private var weekLabel: String {
        if weekOffset == 0 { return "This Week" }
        if weekOffset == -1 { return "Last Week" }
        let today = Calendar.current.startOfDay(for: .now)
        let weekStart = Calendar.current.date(byAdding: .day, value: weekOffset * 7 - 6, to: today) ?? today
        let weekEnd = Calendar.current.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: weekStart)) \u{2013} \(fmt.string(from: weekEnd))"
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
