import SwiftUI

struct TotalActivityView: View {
    let activityData: TotalActivityData

    @State private var expandedAppID: UUID? = nil

    var body: some View {
        // ScrollView lives INSIDE the extension so it runs in the same
        // process as the remote view — host-level ScrollView can't scroll
        // because the remote UIKit layer intercepts touch events.
        ScrollView {
            VStack(spacing: 16) {
                // 1. Octopus Mascot (replaces score ring)
                OctopusMascotView(
                    score: activityData.brainRotScore,
                    totalScreenTime: activityData.formattedDuration
                )
                .padding(.top, 4)

                // 2. Kraken Evolution — show all tiers
                krakenEvolutionCard
                    .padding(.horizontal)

                // 3. Quick Stats Row (Pickups | Avg Session | Frequency)
                QuickStatsRowView(
                    pickups: activityData.totalPickups,
                    avgSessionMinutes: activityData.smartKPIs.avgSessionMinutes,
                    pickupFrequencyMinutes: activityData.smartKPIs.pickupFrequencyMinutes
                )
                .padding(.horizontal)

                // 3. Doom Ratio Bar
                if activityData.smartKPIs.doomRatioPercent > 0 {
                    DoomRatioView(
                        appName: activityData.smartKPIs.doomRatioAppName,
                        percentage: activityData.smartKPIs.doomRatioPercent
                    )
                    .padding(.horizontal)
                }

                // 4. Achievement Banner (conditional)
                if !activityData.smartKPIs.achievements.isEmpty {
                    AchievementBannerView(
                        achievements: activityData.smartKPIs.achievements
                    )
                    .padding(.horizontal)
                }

                // 5. App Breakdown
                if !activityData.allApps.isEmpty {
                    appBreakdownSection
                        .padding(.horizontal)
                }

                // Bottom padding for tab bar clearance
                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
    }

    // MARK: - Kraken Evolution

    private var krakenEvolutionCard: some View {
        let currentMood = OctopusMood.from(score: activityData.brainRotScore)
        let tiers: [(mood: OctopusMood, name: String, range: String, emoji: String)] = [
            (.ecstatic,   "Digital Monk",     "0-19",  "✨"),
            (.happy,      "Grass Toucher",    "20-39", "♪"),
            (.neutral,    "Casual Scroller",  "40-59", "📱"),
            (.sad,        "Doomscroller",     "60-79", "😢"),
            (.distressed, "Brainrot Mode",    "80-94", "🧠"),
            (.zombie,     "Full Brainrot",    "95+",   "💀"),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("Kraken Evolution")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(tiers, id: \.name) { tier in
                        let isCurrent = tier.mood == currentMood
                        // Best tier is first (ecstatic), worst is last (zombie)
                        let isBetter = tiers.firstIndex(where: { $0.mood == tier.mood })! <
                                       tiers.firstIndex(where: { $0.mood == currentMood })!

                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [tier.mood.bodyColor, tier.mood.bodyColorDark],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)

                                Text(tier.emoji)
                                    .font(.system(size: 20))

                                if isCurrent {
                                    Circle()
                                        .stroke(tier.mood.bodyColor, lineWidth: 2.5)
                                        .frame(width: 52, height: 52)
                                }
                            }

                            if isCurrent {
                                Text("YOU")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(tier.mood.bodyColor)
                                    .clipShape(Capsule())
                            }

                            Text(tier.name)
                                .font(.system(size: 10, weight: isCurrent ? .black : .semibold, design: .rounded))
                                .foregroundColor(isCurrent ? tier.mood.bodyColorDark : BrainRotTheme.textSecondary)
                                .lineLimit(1)

                            Text(tier.range)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)

                            if isBetter {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(BrainRotTheme.neonGreen)
                            } else if !isCurrent {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(BrainRotTheme.textSecondary.opacity(0.5))
                            }
                        }
                        .frame(width: 80)
                        .padding(.vertical, 10)
                        .background(
                            isCurrent
                                ? tier.mood.bodyColor.opacity(0.12)
                                : BrainRotTheme.cardBorder.opacity(0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isCurrent ? tier.mood.bodyColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .opacity(isCurrent ? 1.0 : (isBetter ? 0.85 : 0.55))
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - App Breakdown

    private var appBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("App Breakdown")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(activityData.allApps.count) apps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(activityData.allApps.enumerated()), id: \.element.id) { index, app in
                appRow(app: app, rank: index + 1)

                if index < activityData.allApps.count - 1 {
                    Divider()
                        .padding(.leading, 60)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func appRow(app: AppUsageData, rank: Int) -> some View {
        let isExpanded = expandedAppID == app.id

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

    private func expandedDetail(app: AppUsageData) -> some View {
        let percentage = activityData.totalDuration > 0
            ? (app.duration / activityData.totalDuration) * 100
            : 0
        let avgSession = app.numberOfPickups > 0
            ? app.duration / Double(app.numberOfPickups)
            : app.duration

        return VStack(spacing: 10) {
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
                            .frame(width: geo.size.width * min(percentage / 100, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }

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

    private func appIcon(name: String, rank: Int) -> some View {
        let letter = String(name.prefix(1)).uppercased()
        let colors: [Color] = [BrainRotTheme.neonPink, BrainRotTheme.neonPurple, BrainRotTheme.neonOrange, BrainRotTheme.neonBlue, BrainRotTheme.neonGreen]
        let color = rank <= colors.count ? colors[rank - 1] : BrainRotTheme.textSecondary

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
}
