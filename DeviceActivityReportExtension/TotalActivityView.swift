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
                // 1. Octopus Mascot
                OctopusMascotView(
                    score: activityData.brainRotScore,
                    totalScreenTime: activityData.formattedDuration
                )
                .padding(.top, 4)

                // 2. Next Evolution — current tier → next goal
                krakenEvolutionCard
                    .padding(.horizontal)

                // 3. Quick Stats Row (Pickups | Avg Session | Frequency)
                QuickStatsRowView(
                    pickups: activityData.totalPickups,
                    avgSessionMinutes: activityData.smartKPIs.avgSessionMinutes,
                    pickupFrequencyMinutes: activityData.smartKPIs.pickupFrequencyMinutes
                )
                .padding(.horizontal)

                // 4. App Breakdown
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
        let score = activityData.brainRotScore
        let currentMood = OctopusMood.from(score: score)
        let tiers: [(mood: OctopusMood, name: String, maxScore: Int, emoji: String)] = [
            (.ecstatic,   "Digital Monk",    19,  "✨"),
            (.happy,      "Grass Toucher",   39,  "♪"),
            (.neutral,    "Casual Scroller", 59,  "📱"),
            (.sad,        "Doomscroller",    79,  "😢"),
            (.distressed, "Brainrot Mode",   94,  "🧠"),
            (.zombie,     "Full Brainrot",   100, "💀"),
        ]

        let currentIdx = tiers.firstIndex(where: { $0.mood == currentMood }) ?? 0
        let currentTier = tiers[currentIdx]
        // Next better tier (lower index = better)
        let nextTier = currentIdx > 0 ? tiers[currentIdx - 1] : nil
        // Best tier
        let isAlreadyBest = currentMood == .ecstatic

        return HStack(spacing: 14) {
            // Current tier circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [currentMood.bodyColor, currentMood.bodyColorDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                Text(currentTier.emoji)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(currentTier.name)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(currentMood.bodyColorDark)

                if isAlreadyBest {
                    Text("You're at the top! Keep it up \u{1F451}")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.neonGreen)
                } else if let next = nextTier {
                    HStack(spacing: 4) {
                        Text("Next:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BrainRotTheme.textSecondary)
                        Text("\(next.emoji) \(next.name)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(next.mood.bodyColorDark)
                        Text("(score \u{2264} \(next.maxScore))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }
                }
            }

            Spacer(minLength: 0)

            if !isAlreadyBest, let next = nextTier {
                // Arrow pointing to next tier
                ZStack {
                    Circle()
                        .fill(next.mood.bodyColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text(next.emoji)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentMood.bodyColor.opacity(0.3), lineWidth: 1)
        )
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
