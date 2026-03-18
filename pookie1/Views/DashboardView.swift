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
    @State private var refreshTrigger = 0  // bump to force re-render of day scores

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
                // Extension saves today's score when TotalActivityReport renders
                // Refresh pills at 1s, 3s, 5s to catch it
                for delay in [1.0, 3.0, 5.0] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        refreshTrigger += 1
                    }
                }
            }
            .onDisappear {
                pollTimer?.invalidate()
                pollTimer = nil
            }
            .onChange(of: weekOffset) { _, newValue in
                shared?.set(newValue, forKey: "dayPillsWeekOffset")
                shared?.synchronize()
            }
            .onChange(of: selectedDayOffset) { _, _ in
                // After selecting a day, extension saves its score
                for delay in [1.5, 3.0] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        refreshTrigger += 1
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

    private var weekDays: [(date: Date, offset: Int)] {
        let today = Calendar.current.startOfDay(for: .now)
        let weekStart = weekOffset * 7
        return (0..<7).compactMap { i in
            let dayOffset = weekStart - (6 - i) // most recent day on the right
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) ?? today
            // Don't show future days
            if dayOffset > 0 { return nil }
            return (date, dayOffset)
        }
    }

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
        // Show date range
        let today = Calendar.current.startOfDay(for: .now)
        let weekStart = Calendar.current.date(byAdding: .day, value: weekOffset * 7 - 6, to: today) ?? today
        let weekEnd = Calendar.current.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: weekStart)) \u{2013} \(fmt.string(from: weekEnd))"
    }

    private func dayPill(date: Date, offset: Int, isSelected: Bool, isToday: Bool) -> some View {
        let _ = refreshTrigger
        let dateKey = dateKeyString(for: date)
        let storedScore = SharedSettings.scoreForDay(dateKey)
        // Always show a colored octopus — use stored score, or today's live score as fallback
        let dayScore: Int = storedScore ?? SharedSettings.lastScore
        let mood = OctopusMood.from(score: dayScore)

        return VStack(spacing: 2) {
            Text(dayLabel(for: date))
                .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : BrainRotTheme.textSecondary)

            // Mini octopus
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [mood.bodyColor, mood.bodyColorDark],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 2, endRadius: 10
                        )
                    )
                    .frame(width: 24, height: 24)

                // Tiny eyes
                HStack(spacing: 6) {
                    Circle().fill(Color.white).frame(width: 4.5, height: 4.5)
                    Circle().fill(Color.white).frame(width: 4.5, height: 4.5)
                }
                .offset(y: -1)
            }

            Text(dayNumber(for: date))
                .font(.system(size: 10, weight: isSelected ? .black : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : BrainRotTheme.textSecondary)
        }
        .frame(width: 44)
        .padding(.vertical, 6)
        .background(
            isSelected
                ? AnyShapeStyle(
                    LinearGradient(
                        colors: [mood.bodyColor, mood.bodyColorDark],
                        startPoint: .top, endPoint: .bottom
                    )
                  )
                : AnyShapeStyle(
                    LinearGradient(
                        colors: [mood.bodyColor.opacity(0.35), mood.bodyColorDark.opacity(0.2)],
                        startPoint: .top, endPoint: .bottom
                    )
                  )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? mood.bodyColorDark.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
    }

    private func dateKeyString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
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
