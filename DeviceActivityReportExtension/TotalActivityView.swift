import SwiftUI

struct TotalActivityView: View {
    let activityData: TotalActivityData

    var body: some View {
        // ScrollView lives INSIDE the extension so it runs in the same
        // process as the remote view — host-level ScrollView can't scroll
        // because the remote UIKit layer intercepts touch events.
        ScrollView {
            VStack(spacing: 16) {
                // 1. Enhanced Score Ring
                BrainRotScoreView(
                    score: activityData.brainRotScore,
                    totalScreenTime: activityData.formattedDuration
                )
                .padding(.top, 4)

                // 2. Quick Stats Row (Pickups | Avg Session | Frequency)
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

                // 5. Brainrot Leaderboard
                if !activityData.topApps.isEmpty {
                    AppLeaderboardView(
                        apps: activityData.topApps,
                        totalDuration: activityData.totalDuration
                    )
                    .padding(.horizontal)
                }

                // Bottom padding for tab bar clearance
                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
    }
}
