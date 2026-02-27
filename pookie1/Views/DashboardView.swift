import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct DashboardView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedDate = Date.now

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        DatePicker(
                            "Date",
                            selection: $selectedDate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .tint(BrainRotTheme.neonPurple)
                        .foregroundColor(BrainRotTheme.textPrimary)
                        .padding(.horizontal)

                        if screenTimeManager.hasSelectedApps {
                            #if targetEnvironment(simulator)
                            simulatorMockDashboard
                            #else
                            let filter = DeviceActivityFilter(
                                segment: .daily(
                                    during: Calendar.current.dateInterval(of: .day, for: selectedDate)!
                                ),
                                users: .all,
                                devices: .init([.iPhone, .iPad]),
                                applications: screenTimeManager.activitySelection.applicationTokens,
                                categories: screenTimeManager.activitySelection.categoryTokens
                            )
                            DeviceActivityReport(.totalActivity, filter: filter)
                                .frame(minHeight: 400)
                            #endif
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Overview")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("\u{1F9E0}")
                .font(.system(size: 60))
            Text("No apps selected yet")
                .font(.title2.bold())
                .foregroundColor(BrainRotTheme.textPrimary)
            Text("Head to the Apps tab to pick which apps to track")
                .font(.body)
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    #if targetEnvironment(simulator)
    private var simulatorMockDashboard: some View {
        VStack(spacing: 24) {
            BrainRotScoreView(
                score: 72,
                totalScreenTime: "2h 45m"
            )
            .padding(.top, 8)

            HStack(spacing: 12) {
                StatsCardView(
                    title: "Screen Time",
                    value: "2h 45m",
                    icon: "clock.fill",
                    color: BrainRotTheme.neonBlue
                )
                StatsCardView(
                    title: "Apps Used",
                    value: "5",
                    icon: "app.fill",
                    color: BrainRotTheme.neonPurple
                )
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text("Top Brainrot Sources")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                    .padding(.horizontal)

                mockAppRow(name: "TikTok", time: "1h 12m", pickups: 23, rank: 1, color: BrainRotTheme.neonPink)
                mockAppRow(name: "Instagram", time: "48m", pickups: 15, rank: 2, color: BrainRotTheme.neonPurple)
                mockAppRow(name: "X", time: "25m", pickups: 8, rank: 3, color: BrainRotTheme.neonBlue)
                mockAppRow(name: "YouTube", time: "12m", pickups: 4, rank: 4, color: BrainRotTheme.neonGreen)
                mockAppRow(name: "Reddit", time: "8m", pickups: 3, rank: 5, color: BrainRotTheme.neonGreen)
            }
        }
    }

    private func mockAppRow(name: String, time: String, pickups: Int, rank: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.caption.bold())
                .foregroundColor(BrainRotTheme.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.bold())
                    .foregroundColor(BrainRotTheme.textPrimary)
                Text("\(pickups) pickups")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            Text(time)
                .font(.body.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(BrainRotTheme.cardBackground.opacity(0.5))
    }
    #endif
}
