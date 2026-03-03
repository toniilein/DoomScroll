import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct AppAnalyticsHostView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedDayOffset = 0

    private var selectedDate: Date {
        Calendar.current.date(
            byAdding: .day,
            value: selectedDayOffset,
            to: Calendar.current.startOfDay(for: .now)
        )!
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                if !screenTimeManager.isAuthorized {
                    ScrollView {
                        notAuthorizedPrompt
                            .padding(.top)
                    }
                } else {
                    VStack(spacing: 0) {
                        weekDaySelector
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                        #if !targetEnvironment(simulator)
                        DeviceActivityReport(
                            .appAnalytics,
                            filter: screenTimeManager.filterForDate(selectedDate)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #else
                        Text("App Analytics (Simulator)")
                            .foregroundColor(BrainRotTheme.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Week Day Selector

    private var weekDaySelector: some View {
        HStack(spacing: 4) {
            ForEach(-6...0, id: \.self) { offset in
                let date = Calendar.current.date(
                    byAdding: .day,
                    value: offset,
                    to: Calendar.current.startOfDay(for: .now)
                )!
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

                        Circle()
                            .fill(isToday
                                  ? (isSelected ? Color.white : BrainRotTheme.neonPink)
                                  : Color.clear
                            )
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isSelected
                            ? AnyShapeStyle(BrainRotTheme.accentGradient)
                            : AnyShapeStyle(BrainRotTheme.cardBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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

    // MARK: - Not Authorized

    private var notAuthorizedPrompt: some View {
        VStack(spacing: 16) {
            Text("\u{1F4CA}")
                .font(.system(size: 48))

            Text("Enable Screen Time")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)

            Text("Grant Screen Time access to see per-app analytics")
                .font(.body)
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await screenTimeManager.requestAuthorization() }
            } label: {
                Text("Enable")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BrainRotTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
}
