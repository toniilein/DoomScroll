import SwiftUI

struct AchievementBannerView: View {
    let achievements: [DoomAchievement]

    var body: some View {
        if let achievement = achievements.first {
            HStack(spacing: 12) {
                Text(achievement.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ACHIEVEMENT UNLOCKED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(achievement.color.opacity(0.8))
                        .tracking(2)

                    Text(achievement.title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                }

                Spacer()

                if achievements.count > 1 {
                    Text("+\(achievements.count - 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(achievement.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(achievement.color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(BrainRotTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(achievement.color.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: achievement.color.opacity(0.2), radius: 8, y: 4)
        }
    }
}
