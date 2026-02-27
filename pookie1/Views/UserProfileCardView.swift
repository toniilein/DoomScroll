import SwiftUI

struct UserProfileCardView: View {
    let displayName: String
    let username: String
    let brainRotScore: Int
    let formattedScreenTime: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.title3.bold())
                    .foregroundColor(BrainRotTheme.textPrimary)

                Text("@\(username)")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text(formattedScreenTime)
                        .font(.subheadline.bold())
                }
                .foregroundColor(BrainRotTheme.neonBlue)

                Text(BrainRotTheme.scoreLabel(for: brainRotScore))
                    .font(.caption.bold())
                    .foregroundColor(BrainRotTheme.scoreColor(for: brainRotScore))
            }

            Spacer()

            // Mini score ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: Double(brainRotScore) / 100.0)
                    .stroke(
                        BrainRotTheme.scoreColor(for: brainRotScore),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                Text("\(brainRotScore)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.scoreColor(for: brainRotScore))
            }
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.scoreColor(for: brainRotScore).opacity(0.3), lineWidth: 1)
        )
    }
}
