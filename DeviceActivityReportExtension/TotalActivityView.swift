import SwiftUI

struct TotalActivityView: View {
    let activityReport: ActivityReportData

    var body: some View {
        VStack(spacing: 24) {
            BrainRotScoreView(
                score: activityReport.brainRotScore,
                totalScreenTime: activityReport.formattedDuration
            )
            .padding(.top, 8)

            HStack(spacing: 12) {
                StatsCardView(
                    title: "Screen Time",
                    value: activityReport.formattedDuration,
                    icon: "clock.fill",
                    color: BrainRotTheme.neonBlue
                )
                StatsCardView(
                    title: "Apps Used",
                    value: "\(activityReport.topApps.count)",
                    icon: "app.fill",
                    color: BrainRotTheme.neonPurple
                )
            }
            .padding(.horizontal)

            if !activityReport.topApps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Brainrot Sources")
                        .font(.headline)
                        .foregroundColor(BrainRotTheme.textPrimary)
                        .padding(.horizontal)

                    ForEach(Array(activityReport.topApps.enumerated()), id: \.element.id) { index, app in
                        appRow(app: app, rank: index + 1)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(BrainRotTheme.background)
    }

    private func appRow(app: AppUsageData, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.caption.bold())
                .foregroundColor(BrainRotTheme.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.displayName)
                    .font(.body.bold())
                    .foregroundColor(BrainRotTheme.textPrimary)
                    .lineLimit(1)

                Text("\(app.numberOfPickups) pickups")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            Text(app.formattedDuration)
                .font(.body.bold())
                .foregroundColor(appDurationColor(app.duration))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(BrainRotTheme.cardBackground.opacity(0.5))
    }

    private func appDurationColor(_ duration: TimeInterval) -> Color {
        let minutes = duration / 60.0
        switch minutes {
        case ..<15: return BrainRotTheme.neonGreen
        case 15..<45: return BrainRotTheme.neonBlue
        case 45..<90: return BrainRotTheme.neonPurple
        default: return BrainRotTheme.neonPink
        }
    }
}
