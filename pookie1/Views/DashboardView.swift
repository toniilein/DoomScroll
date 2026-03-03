import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct DashboardView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedDayOffset = 0 // 0 = today, -1 = yesterday, etc.

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
                    // NO host ScrollView — the extension's internal ScrollView
                    // handles scrolling (remote views intercept host gestures).
                    VStack(spacing: 0) {
                        // Week day selector (interactive, lives in host process)
                        weekDaySelector
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                        #if !targetEnvironment(simulator)
                        // Report fills remaining space; its internal ScrollView scrolls
                        DeviceActivityReport(.totalActivity, filter: screenTimeManager.filterForDate(selectedDate))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif
                    }
                }
            }
            .navigationTitle("Overview")
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    // MARK: - Week Day Selector

    private var weekDaySelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(-29...0, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now)) ?? .now
                        let isSelected = offset == selectedDayOffset
                        let isToday = offset == 0

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDayOffset = offset
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(dayLabel(for: date))
                                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .white : BrainRotTheme.textSecondary)

                                Text(dayNumber(for: date))
                                    .font(.system(size: 15, weight: isSelected ? .black : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? .white : BrainRotTheme.textPrimary)

                                if isToday {
                                    Circle()
                                        .fill(isSelected ? Color.white : BrainRotTheme.neonPink)
                                        .frame(width: 4, height: 4)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .frame(width: 44)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(BrainRotTheme.accentGradient)
                                    : AnyShapeStyle(BrainRotTheme.cardBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .id(offset)
                    }
                }
            }
            .onAppear {
                proxy.scrollTo(selectedDayOffset, anchor: .trailing)
            }
        }
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
