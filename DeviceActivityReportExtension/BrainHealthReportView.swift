import SwiftUI

struct BrainHealthReportView: View {
    let healthData: BrainHealthData

    var body: some View {
        // ScrollView lives INSIDE the extension so it runs in the same
        // process as the remote view — the host cannot scroll remote views.
        ScrollView {
            VStack(spacing: 16) {
                // 0. Weekly Trend Chart (merged into this single report)
                WeeklyTrendView(trendData: healthData.weeklyTrend)
                    .padding(.horizontal)

                // 1. Score Ring with "Brain Remaining" subtitle
                BrainRotScoreView(
                    score: healthData.brainRotScore,
                    totalScreenTime: healthData.formattedDuration,
                    subtitle: "Brain Remaining: \(healthData.smartKPIs.brainRemaining)%",
                    compact: true
                )
                .padding(.top, 4)

                // 2. Brain Damage Meter
                BrainDamageMeterView(score: healthData.brainRotScore)
                    .padding(.horizontal)

                // 3. Metrics Grid (2x2)
                MetricsGridView(
                    addictionIndex: healthData.smartKPIs.addictionIndex,
                    pickupsPerHour: healthData.smartKPIs.pickupsPerHour,
                    longestSessionMinutes: healthData.longestSessionMinutes,
                    focusDestroyerApp: healthData.smartKPIs.focusDestroyerApp,
                    focusDestroyerPickups: healthData.smartKPIs.focusDestroyerPickups
                )
                .padding(.horizontal)

                // 4. Scroll Type Card
                ScrollTypeView(scrollType: healthData.smartKPIs.scrollType)
                    .padding(.horizontal)

                // 5. Achievement Banner (if any)
                if !healthData.smartKPIs.achievements.isEmpty {
                    AchievementBannerView(
                        achievements: healthData.smartKPIs.achievements
                    )
                    .padding(.horizontal)
                }

                // 6. App Leaderboard
                if !healthData.topApps.isEmpty {
                    AppLeaderboardView(
                        apps: healthData.topApps,
                        totalDuration: healthData.totalDuration
                    )
                    .padding(.horizontal)
                }

                // 7. Daily Challenge
                DailyChallengeView(
                    score: healthData.brainRotScore,
                    pickups: healthData.totalPickups
                )
                .padding(.horizontal)

                // Bottom padding for tab bar clearance
                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
    }
}
