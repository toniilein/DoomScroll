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

                // 2. Recommendations
                recommendationsCard
                    .padding(.horizontal)

                // 3. 7-Day App Analysis
                if !healthData.appDailyUsages.isEmpty {
                    weeklyAppAnalysisSection
                        .padding(.horizontal)
                }

                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
        .preferredColorScheme(SharedTheme.colorScheme)
    }

    // MARK: - Recommendations

    private var recommendationsCard: some View {
        let tips = generateTips()

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(BrainRotTheme.neonOrange)
                Text(L("brainHealth.recommendations"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
            }

            ForEach(tips, id: \.icon) { tip in
                if tip.isAction {
                    HStack(alignment: .top, spacing: 10) {
                        Text(tip.icon)
                            .font(.system(size: 22))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                            Text(tip.detail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 4) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 10))
                                Text(L("brainHealth.goToShield"))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(BrainRotTheme.neonPurple)
                            .padding(.top, 2)
                        }
                    }
                    .padding(12)
                    .background(BrainRotTheme.neonPurple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        Text(tip.icon)
                            .font(.system(size: 22))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(tip.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                            Text(tip.detail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.cardBorder, lineWidth: 1)
        )
    }

    private struct Tip {
        let icon: String
        let title: String
        let detail: String
        var isAction: Bool = false
    }

    private func generateTips() -> [Tip] {
        var tips: [Tip] = []
        let score = healthData.brainRotScore
        let pickups = healthData.totalPickups
        let topApp = healthData.topApps.first

        // Always show usage limit recommendation first
        if let app = topApp {
            let dailyAvgMinutes = Int(app.duration / 60.0 / 7.0)
            let suggestedLimit = max(15, (dailyAvgMinutes / 15) * 15) // round down to nearest 15m
            tips.append(Tip(
                icon: "\u{1F6E1}\u{FE0F}",
                title: String(format: L("brainHealth.setLimit"), app.displayName),
                detail: String(format: L("brainHealth.setLimitDetail"), dailyAvgMinutes, app.displayName, suggestedLimit),
                isAction: true
            ))
        } else {
            tips.append(Tip(
                icon: "\u{1F6E1}\u{FE0F}",
                title: L("brainHealth.addLimit"),
                detail: L("brainHealth.addLimitDetail"),
                isAction: true
            ))
        }

        // Tip based on score range
        if score >= 80 {
            tips.append(Tip(
                icon: "\u{1F6A8}",
                title: L("brainHealth.screenTimeHigh"),
                detail: L("brainHealth.screenTimeHighDetail")
            ))
        } else if score >= 50 {
            tips.append(Tip(
                icon: "\u{26A0}\u{FE0F}",
                title: L("brainHealth.roomToImprove"),
                detail: L("brainHealth.roomToImproveDetail")
            ))
        } else {
            tips.append(Tip(
                icon: "\u{2705}",
                title: L("brainHealth.greatJob"),
                detail: L("brainHealth.greatJobDetail")
            ))
        }

        // Tip based on pickups
        if pickups > 200 {
            tips.append(Tip(
                icon: "\u{1F4F1}",
                title: L("brainHealth.tooManyPickups"),
                detail: String(format: L("brainHealth.tooManyPickupsDetail"), pickups)
            ))
        } else if pickups > 100 {
            tips.append(Tip(
                icon: "\u{1F514}",
                title: L("brainHealth.watchPickups"),
                detail: String(format: L("brainHealth.watchPickupsDetail"), pickups)
            ))
        }

        // Tip based on top app
        if let app = topApp, app.duration > 7200 {
            let hours = Int(app.duration / 3600)
            tips.append(Tip(
                icon: "\u{23F0}",
                title: String(format: L("brainHealth.biggestDrain"), app.displayName),
                detail: String(format: L("brainHealth.biggestDrainDetail"), hours)
            ))
        }

        return tips
    }

    // MARK: - Weekly App Analysis

    private var weeklyAppAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("7-Day App Usage")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(healthData.appDailyUsages.count) \(L("breakdown.apps"))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(healthData.appDailyUsages.enumerated()), id: \.element.id) { index, app in
                weeklyAppRow(app: app, rank: index + 1)

                if index < healthData.appDailyUsages.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func weeklyAppRow(app: AppDailyUsage, rank: Int) -> some View {
        let isExpanded = expandedAppID == app.id
        let color = iconColor(for: rank)
        let maxDuration = app.dailyDurations.max() ?? 1

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : app.id
                }
            } label: {
                HStack(spacing: 12) {
                    appIcon(name: app.displayName, rank: rank)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)
                        Text(app.formattedTotal + " total")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    // Mini sparkline
                    miniSparkline(durations: app.dailyDurations, color: color)
                        .frame(width: 50, height: 20)

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
                weeklyAppDetail(app: app, color: color, maxDuration: maxDuration)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func miniSparkline(durations: [TimeInterval], color: Color) -> some View {
        let maxVal = durations.max() ?? 1
        return GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<durations.count, id: \.self) { i in
                    let h = maxVal > 0 ? CGFloat(durations[i] / maxVal) * geo.size.height : 0
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(durations[i] > 0 ? color : BrainRotTheme.cardBorder)
                        .frame(width: 4, height: max(2, h))
                }
            }
        }
    }

    private func weeklyAppDetail(app: AppDailyUsage, color: Color, maxDuration: TimeInterval) -> some View {
        let dailyAvg = app.totalDuration / 7.0

        return VStack(spacing: 12) {
            // Daily avg
            HStack {
                Text("Daily Avg")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                Text(BrainRotCalculator.formatDuration(dailyAvg))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<app.dailyDurations.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        let dur = app.dailyDurations[i]
                        let barHeight = maxDuration > 0 ? CGFloat(dur / maxDuration) * 60 : 0

                        if dur > 0 {
                            Text(formatShort(dur))
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(color)
                        }

                        RoundedRectangle(cornerRadius: 3)
                            .fill(dur > 0 ? color : BrainRotTheme.cardBorder)
                            .frame(height: max(4, barHeight))

                        Text(app.dayLabels[i])
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .padding(.top, 4)
        .background(color.opacity(0.04))
    }

    private func formatShort(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h\(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }

    // MARK: - App Breakdown Section

    private var appBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text(L("breakdown.appBreakdown"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(healthData.allApps.count) \(L("breakdown.apps"))")
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
                            Text("\(app.numberOfPickups) \(L("breakdown.pickups"))")
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
                    Text(L("breakdown.screenTimeShare"))
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
                miniStat(icon: "clock.fill", title: L("breakdown.duration"), value: app.formattedDuration)
                miniStat(icon: "hand.tap.fill", title: L("breakdown.pickups"), value: "\(app.numberOfPickups)")
                miniStat(icon: "timer", title: L("breakdown.avgSession"), value: BrainRotCalculator.formatDuration(avgSession))
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

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text(L("breakdown.categoryBreakdown"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(healthData.categories.count) \(L("breakdown.groups"))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(healthData.categories.enumerated()), id: \.element.id) { index, category in
                categoryRow(category: category, rank: index + 1)

                if index < healthData.categories.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func categoryRow(category: CategoryUsageData, rank: Int) -> some View {
        let isExpanded = expandedAppID == category.id
        let color = iconColor(for: rank)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : category.id
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        Image(systemName: categorySystemIcon(category.categoryName))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.categoryName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Image(systemName: "app.fill")
                                .font(.system(size: 9))
                            Text("\(category.apps.count) \(L("breakdown.apps"))")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    Text(category.formattedDuration)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(color)

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
                categoryExpandedDetail(category: category, rank: rank)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func categoryExpandedDetail(category: CategoryUsageData, rank: Int) -> some View {
        let percentage = healthData.totalDuration > 0
            ? (category.duration / healthData.totalDuration) * 100 : 0
        let avgSession = category.pickups > 0
            ? category.duration / Double(category.pickups) : category.duration
        let color = iconColor(for: rank)

        return VStack(spacing: 10) {
            HStack(spacing: 0) {
                miniStat(icon: "clock.fill", title: L("breakdown.duration"), value: category.formattedDuration)
                miniStat(icon: "hand.tap.fill", title: L("breakdown.pickups"), value: "\(category.pickups)")
                miniStat(icon: "timer", title: L("breakdown.avgSession"), value: BrainRotCalculator.formatDuration(avgSession))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(L("breakdown.screenTimeShare"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geo.size.width * min(percentage / 100, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // App list within category
            if !category.apps.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L("common.apps"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                        .padding(.bottom, 6)

                    ForEach(category.apps) { app in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(color.opacity(0.3))
                                .frame(width: 6, height: 6)
                            Text(app.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BrainRotTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(app.formattedDuration)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 2)
        .background(color.opacity(0.04))
    }

    private func categorySystemIcon(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("social") { return "bubble.left.and.bubble.right.fill" }
        if lower.contains("entertainment") || lower.contains("video") { return "play.tv.fill" }
        if lower.contains("game") { return "gamecontroller.fill" }
        if lower.contains("productivity") { return "briefcase.fill" }
        if lower.contains("education") { return "graduationcap.fill" }
        if lower.contains("health") || lower.contains("fitness") { return "heart.fill" }
        if lower.contains("shopping") { return "cart.fill" }
        if lower.contains("news") || lower.contains("reading") { return "newspaper.fill" }
        if lower.contains("photo") || lower.contains("creative") { return "camera.fill" }
        if lower.contains("music") { return "music.note" }
        if lower.contains("travel") || lower.contains("navigation") { return "map.fill" }
        if lower.contains("finance") || lower.contains("business") { return "chart.line.uptrend.xyaxis" }
        if lower.contains("utility") || lower.contains("utilities") { return "wrench.fill" }
        if lower.contains("communication") || lower.contains("message") { return "message.fill" }
        return "square.grid.2x2.fill"
    }
}
