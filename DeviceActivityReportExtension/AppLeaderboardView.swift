import SwiftUI

struct AppLeaderboardView: View {
    let apps: [AppUsageData]
    let totalDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(BrainRotTheme.goldColor)
                Text("Brainrot Leaderboard")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            ForEach(Array(apps.prefix(5).enumerated()), id: \.element.id) { index, app in
                leaderboardRow(rank: index + 1, app: app)
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func leaderboardRow(rank: Int, app: AppUsageData) -> some View {
        HStack(spacing: 10) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(rank).opacity(0.2))
                    .frame(width: 32, height: 32)

                if rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundColor(BrainRotTheme.goldColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(rankColor(rank))
                }
            }

            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Pickup badge
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 9))
                    Text("\(app.numberOfPickups) pickups")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            // Duration + progress bar
            VStack(alignment: .trailing, spacing: 4) {
                Text(app.formattedDuration)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.scoreColor(
                        for: BrainRotCalculator.score(totalMinutes: app.duration / 60.0)
                    ))

                // Mini progress bar
                GeometryReader { geo in
                    let ratio = totalDuration > 0 ? app.duration / totalDuration : 0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(BrainRotTheme.scoreColor(
                                for: BrainRotCalculator.score(totalMinutes: app.duration / 60.0)
                            ))
                            .frame(width: geo.size.width * ratio, height: 3)
                    }
                }
                .frame(width: 60, height: 3)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            rank == 1
                ? BrainRotTheme.goldColor.opacity(0.05)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return BrainRotTheme.goldColor
        case 2: return BrainRotTheme.silverColor
        case 3: return BrainRotTheme.bronzeColor
        default: return BrainRotTheme.textSecondary
        }
    }
}
