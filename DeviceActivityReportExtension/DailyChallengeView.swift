import SwiftUI

struct DailyChallengeView: View {
    let score: Int
    let pickups: Int

    var body: some View {
        HStack(spacing: 12) {
            // Game-style icon
            ZStack {
                Circle()
                    .fill(BrainRotTheme.neonOrange.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(BrainRotTheme.neonOrange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("DAILY CHALLENGE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(BrainRotTheme.neonOrange.opacity(0.8))
                    .tracking(1.5)

                Text(BrainRotCalculator.dailyChallenge(for: score, pickups: pickups))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(BrainRotTheme.neonOrange.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(BrainRotTheme.neonOrange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
