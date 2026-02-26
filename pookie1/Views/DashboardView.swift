import SwiftUI
import DeviceActivity

struct DashboardView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedDate = Date.now

    private var filter: DeviceActivityFilter {
        let dateInterval = Calendar.current.dateInterval(of: .day, for: selectedDate)!
        return DeviceActivityFilter(
            segment: .daily(during: dateInterval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: screenTimeManager.activitySelection.applicationTokens,
            categories: screenTimeManager.activitySelection.categoryTokens
        )
    }

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
                            DeviceActivityReport(.totalActivity, filter: filter)
                                .frame(minHeight: 400)
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Dashboard")
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
}
