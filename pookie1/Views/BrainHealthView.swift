import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct BrainHealthView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedDayOffset = 0

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDayOffset, to: Calendar.current.startOfDay(for: .now))!
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                if !screenTimeManager.isAuthorized {
                    ScrollView {
                        notAuthorizedState
                            .padding(.top)
                    }
                } else {
                    #if !targetEnvironment(simulator)
                    ZStack {
                        // Loading placeholder while extension connects
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(BrainRotTheme.neonPurple)
                            Text("Loading...")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }

                        DeviceActivityReport(.brainHealth, filter: screenTimeManager.weeklyFilter())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    #endif
                }
            }
            .navigationTitle("Brain Health")
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(-29...0, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now))!
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

    private var notAuthorizedState: some View {
        VStack(spacing: 16) {
            Text("\u{1F9E0}")
                .font(.system(size: 60))
            Text("Screen Time Required")
                .font(.title2.bold())
                .foregroundColor(BrainRotTheme.textPrimary)
            Text("Enable Screen Time on the Overview tab to see your brain health data")
                .font(.body)
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
