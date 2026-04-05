import SwiftUI

struct AppAnalyticsView: View {
    let data: AppAnalyticsData

    @State private var expandedAppID: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // MARK: - Summary Header
                summaryHeader
                    .padding(.horizontal)

                // MARK: - App List
                if data.allApps.isEmpty {
                    emptyState
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(data.allApps.enumerated()), id: \.element.id) { index, app in
                            appRow(app: app, rank: index + 1)

                            if index < data.allApps.count - 1 {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(BrainRotTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: 0) {
            statPill(
                icon: "app.fill",
                value: "\(data.appCount)",
                label: "Apps",
                color: BrainRotTheme.neonBlue
            )

            statPill(
                icon: "clock.fill",
                value: data.formattedTotalDuration,
                label: "Total",
                color: BrainRotTheme.neonPurple
            )

            statPill(
                icon: "hand.tap.fill",
                value: "\(data.totalPickups)",
                label: "Pickups",
                color: BrainRotTheme.neonPink
            )
        }
        .padding(12)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - App Row

    private func appRow(app: AppUsageData, rank: Int) -> some View {
        let isExpanded = expandedAppID == app.id

        return VStack(spacing: 0) {
            // Main row — always visible
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : app.id
                }
            } label: {
                HStack(spacing: 12) {
                    // App icon placeholder
                    appIconCircle(name: app.displayName, rank: rank)

                    // App name + pickups summary
                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 9))
                            Text("\(app.numberOfPickups) pickups")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    // Duration
                    Text(app.formattedDuration)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(appColor(for: app))

                    // Expand chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                expandedDetail(app: app)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - App Icon Circle

    private func appIconCircle(name: String, rank: Int) -> some View {
        let letter = String(name.prefix(1)).uppercased()
        let color = iconColor(for: rank)

        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            Text(letter)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    // MARK: - Expanded Detail

    private func expandedDetail(app: AppUsageData) -> some View {
        let percentage = data.totalDuration > 0
            ? (app.duration / data.totalDuration) * 100
            : 0
        let avgSession = app.numberOfPickups > 0
            ? app.duration / Double(app.numberOfPickups)
            : app.duration

        return VStack(spacing: 12) {
            // Percentage bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Screen Time Share")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(appColor(for: app))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [appColor(for: app), appColor(for: app).opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * min(percentage / 100, 1.0),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }

            // Stats grid
            HStack(spacing: 0) {
                detailStat(
                    icon: "clock.fill",
                    title: "Duration",
                    value: app.formattedDuration
                )
                detailStat(
                    icon: "hand.tap.fill",
                    title: "Pickups",
                    value: "\(app.numberOfPickups)"
                )
                detailStat(
                    icon: "timer",
                    title: "Avg Session",
                    value: BrainRotCalculator.formatDuration(avgSession)
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .padding(.top, 4)
        .background(appColor(for: app).opacity(0.04))
    }

    private func detailStat(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(BrainRotTheme.textSecondary)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("\u{1F4F1}")
                .font(.system(size: 48))

            Text("No App Data")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)

            Text("No screen time recorded for this day")
                .font(.system(size: 14))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func appColor(for app: AppUsageData) -> Color {
        BrainRotTheme.categoryColor(for: app.categoryName)
    }

    private func iconColor(for rank: Int) -> Color {
        // Fallback for rank-based — not used when categoryName is available
        let colors: [Color] = [BrainRotTheme.neonPink, BrainRotTheme.neonPurple, BrainRotTheme.neonOrange, BrainRotTheme.neonBlue, BrainRotTheme.neonGreen]
        return rank <= colors.count ? colors[rank - 1] : BrainRotTheme.textSecondary
    }
}
