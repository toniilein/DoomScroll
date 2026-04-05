import SwiftUI

struct BrainHealthReportView: View {
    let healthData: BrainHealthData

    @State private var expandedAppID: UUID? = nil
    @State private var showCategories: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Weekly Trend Chart
                WeeklyTrendView(trendData: healthData.weeklyTrend)
                    .padding(.horizontal)

                // 2. This Week summary
                thisWeekCard
                    .padding(.horizontal)

                // 3. Breakdown toggle + content
                breakdownToggle
                    .padding(.horizontal)

                if showCategories {
                    if !healthData.categoryDailyUsages.isEmpty {
                        weeklyCategoryAnalysisSection
                            .padding(.horizontal)
                    }
                } else {
                    if !healthData.appDailyUsages.isEmpty {
                        weeklyAppAnalysisSection
                            .padding(.horizontal)
                    }
                }

                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
        .preferredColorScheme(SharedTheme.colorScheme)
    }

    // MARK: - This Week Card

    private var thisWeekCard: some View {
        let score = healthData.brainRotScore
        let emoji = BrainRotTheme.scoreEmoji(for: score)
        let label = BrainRotTheme.scoreLabel(for: score)
        let color = BrainRotTheme.scoreColor(for: score)
        let trend = healthData.weeklyTrend.trend
        let streak = healthData.weeklyTrend.streakDays

        let mood = OctopusMood.from(score: score)

        return HStack(spacing: 12) {
            MiniOctopusView(mood: mood)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(color)

                Text(weekSummaryMessage(score: score, trend: trend, streak: streak))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func weekSummaryMessage(score: Int, trend: TrendDirection, streak: Int) -> String {
        let topApps = healthData.topApps.prefix(3)
        let topNames = topApps.map { $0.displayName }
        let appList = topNames.joined(separator: ", ")

        switch score {
        case 0..<30:
            if streak >= 3 {
                return "Amazing week! \(streak)-day streak of healthy screen time. Keep it up! 🔥"
            }
            if let first = topNames.first {
                return "Great week! Even \(first) stayed under control. Keep the momentum going! 🎉"
            }
            return "Great job this week! Your screen time is well under control. 🎉"
        case 30..<60:
            if topNames.count >= 2 {
                return "\(topNames[0]) and \(topNames[1]) are your biggest time drains. Try setting limits on them to level up."
            } else if let first = topNames.first {
                return "\(first) is eating most of your screen time. A daily limit could make a big difference."
            }
            return "Not bad, but there's room to cut back. Try setting limits on your top apps."
        case 60..<85:
            if topNames.count >= 2 {
                return "\(topNames[0]) and \(topNames[1]) are driving your doomscroll score up. Consider blocking them during focus hours."
            } else if let first = topNames.first {
                return "\(first) is your biggest doomscroll culprit. Try blocking it with the Panic Button."
            }
            return "Heavy usage this week. Your top apps are dragging your score down."
        default:
            if topNames.count >= 3 {
                return "\(appList) are melting your brain. Time to hit the Panic Button and take a break!"
            } else if let first = topNames.first {
                return "\(first) is destroying your screen time. Seriously — hit the Panic Button!"
            }
            return "Your brain needs a break! Try the Panic Button on the Shield tab."
        }
    }

    private func weekStatPill(icon: String, value: String, label: String, color: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color ?? BrainRotTheme.textSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Breakdown Toggle

    private var breakdownToggle: some View {
        Picker("", selection: $showCategories) {
            Text(L("breakdown.appBreakdown")).tag(false)
            Text(L("breakdown.categoryBreakdown")).tag(true)
        }
        .pickerStyle(.segmented)
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
                Text(L("analysis.7dayApp"))
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
        let color = BrainRotTheme.categoryColor(for: app.categoryName)
        let maxDuration = app.dailyDurations.max() ?? 1

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : app.id
                }
            } label: {
                HStack(spacing: 12) {
                    appIcon(name: app.displayName, categoryName: app.categoryName)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)
                        Text(app.formattedTotal + " " + L("analysis.total"))
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
                Text(L("analysis.dailyAvg"))
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

    // MARK: - Weekly Category Analysis (7-day style)

    private var weeklyCategoryAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text(L("analysis.7dayCat"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(healthData.categoryDailyUsages.count) \(L("breakdown.groups"))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(healthData.categoryDailyUsages.enumerated()), id: \.element.id) { index, cat in
                weeklyCategoryRow(cat: cat)

                if index < healthData.categoryDailyUsages.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func weeklyCategoryRow(cat: CategoryDailyUsage) -> some View {
        let isExpanded = expandedAppID == cat.id
        let color = BrainRotTheme.categoryColor(for: cat.categoryName)
        let maxDuration = cat.dailyDurations.max() ?? 1

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : cat.id
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
                        Image(systemName: categorySystemIcon(cat.categoryName))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(cat.categoryName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)
                        Text(cat.formattedTotal + " " + L("analysis.total") + " \u{00B7} \(cat.appCount) \(L("breakdown.apps"))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    miniSparkline(durations: cat.dailyDurations, color: color)
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
                weeklyCategoryDetail(cat: cat, color: color, maxDuration: maxDuration)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func weeklyCategoryDetail(cat: CategoryDailyUsage, color: Color, maxDuration: TimeInterval) -> some View {
        let dailyAvg = cat.totalDuration / 7.0

        return VStack(spacing: 12) {
            HStack {
                Text(L("analysis.dailyAvg"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                Text(BrainRotCalculator.formatDuration(dailyAvg))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<cat.dailyDurations.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        let dur = cat.dailyDurations[i]
                        let barHeight = maxDuration > 0 ? CGFloat(dur / maxDuration) * 60 : 0

                        if dur > 0 {
                            Text(formatShort(dur))
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(color)
                        }

                        RoundedRectangle(cornerRadius: 3)
                            .fill(dur > 0 ? color : BrainRotTheme.cardBorder)
                            .frame(height: max(4, barHeight))

                        Text(cat.dayLabels[i])
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
                    appIcon(name: app.displayName, categoryName: app.categoryName)

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

    private func appIcon(name: String, categoryName: String) -> some View {
        let letter = String(name.first(where: { $0.isLetter }) ?? "?").uppercased()
        let color = BrainRotTheme.categoryColor(for: categoryName)
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
        BrainRotTheme.categoryColor(for: app.categoryName)
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
        let color = BrainRotTheme.categoryColor(for: category.categoryName)

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
        let color = BrainRotTheme.categoryColor(for: category.categoryName)

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
