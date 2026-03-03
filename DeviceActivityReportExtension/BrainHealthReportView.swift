import SwiftUI

struct BrainHealthReportView: View {
    let healthData: BrainHealthData

    @State private var expandedAppID: UUID? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Weekly Trend Chart
                WeeklyTrendView(trendData: healthData.weeklyTrend)
                    .padding(.horizontal)

                // 2. Metrics Grid (2x2)
                MetricsGridView(
                    addictionIndex: healthData.smartKPIs.addictionIndex,
                    pickupsPerHour: healthData.smartKPIs.pickupsPerHour,
                    longestSessionMinutes: healthData.longestSessionMinutes,
                    focusDestroyerApp: healthData.smartKPIs.focusDestroyerApp,
                    focusDestroyerPickups: healthData.smartKPIs.focusDestroyerPickups
                )
                .padding(.horizontal)

                // 3. Scroll Type Card
                ScrollTypeView(scrollType: healthData.smartKPIs.scrollType)
                    .padding(.horizontal)

                // 4. Doom Ratio
                if healthData.smartKPIs.doomRatioPercent > 0 {
                    DoomRatioView(
                        appName: healthData.smartKPIs.doomRatioAppName,
                        percentage: healthData.smartKPIs.doomRatioPercent
                    )
                    .padding(.horizontal)
                }

                // 5. App Breakdown
                if !healthData.allApps.isEmpty {
                    appBreakdownSection
                        .padding(.horizontal)
                }

                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
    }

    // MARK: - App Breakdown Section

    private var appBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("App Breakdown")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(healthData.allApps.count) apps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // App rows
            ForEach(Array(healthData.allApps.enumerated()), id: \.element.id) { index, app in
                appRow(app: app, rank: index + 1)

                if index < healthData.allApps.count - 1 {
                    Divider()
                        .padding(.leading, 60)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - App Row

    private func appRow(app: AppUsageData, rank: Int) -> some View {
        let isExpanded = expandedAppID == app.id

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : app.id
                }
            } label: {
                HStack(spacing: 12) {
                    // Colored icon circle
                    appIcon(name: app.displayName, rank: rank)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .semibold))
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

                    Text(app.formattedDuration)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(appColor(for: app))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedDetail(app: app)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Expanded Detail

    private func expandedDetail(app: AppUsageData) -> some View {
        let percentage = healthData.totalDuration > 0
            ? (app.duration / healthData.totalDuration) * 100
            : 0
        let avgSession = app.numberOfPickups > 0
            ? app.duration / Double(app.numberOfPickups)
            : app.duration

        return VStack(spacing: 10) {
            // Percentage bar
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Screen Time Share")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(appColor(for: app))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(appColor(for: app))
                            .frame(
                                width: geo.size.width * min(percentage / 100, 1.0),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
            }

            // Stats row
            HStack(spacing: 0) {
                miniStat(icon: "clock.fill", title: "Duration", value: app.formattedDuration)
                miniStat(icon: "hand.tap.fill", title: "Pickups", value: "\(app.numberOfPickups)")
                miniStat(icon: "timer", title: "Avg Session", value: BrainRotCalculator.formatDuration(avgSession))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 2)
        .background(appColor(for: app).opacity(0.04))
    }

    private func miniStat(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(BrainRotTheme.textSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func appIcon(name: String, rank: Int) -> some View {
        let letter = String(name.prefix(1)).uppercased()
        let color = iconColor(for: rank)
        return ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 36, height: 36)
            Text(letter)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private func appColor(for app: AppUsageData) -> Color {
        BrainRotTheme.scoreColor(for: BrainRotCalculator.score(totalMinutes: app.duration / 60.0))
    }

    private func iconColor(for rank: Int) -> Color {
        switch rank {
        case 1:  return BrainRotTheme.neonPink
        case 2:  return BrainRotTheme.neonPurple
        case 3:  return BrainRotTheme.neonOrange
        case 4:  return BrainRotTheme.neonBlue
        case 5:  return BrainRotTheme.neonGreen
        default: return BrainRotTheme.textSecondary
        }
    }
}
