import SwiftUI

/// A compact, non-animated card rendered to an image for sharing.
/// Contains only abstract data (tier name + streak) — no screen time numbers.
struct KrakenShareCardView: View {
    let score: Int
    let streakDays: Int

    private var tierName: String { BrainRotTheme.scoreLabel(for: score) }
    private var tierEmoji: String { BrainRotTheme.scoreEmoji(for: score) }
    private var tierColor: Color { BrainRotTheme.tierBadgeColor(for: score) }

    private var bodyColor: Color {
        switch score {
        case 0..<20:  return Color(red: 0.55, green: 0.88, blue: 0.70)
        case 20..<40: return Color(red: 0.52, green: 0.82, blue: 0.78)
        case 40..<60: return Color(red: 0.60, green: 0.74, blue: 0.90)
        case 60..<80: return Color(red: 0.75, green: 0.62, blue: 0.88)
        case 80..<95: return Color(red: 0.92, green: 0.58, blue: 0.58)
        default:      return Color(red: 0.68, green: 0.65, blue: 0.63)
        }
    }

    private var bodyColorDark: Color {
        switch score {
        case 0..<20:  return Color(red: 0.40, green: 0.75, blue: 0.55)
        case 20..<40: return Color(red: 0.38, green: 0.70, blue: 0.65)
        case 40..<60: return Color(red: 0.48, green: 0.62, blue: 0.78)
        case 60..<80: return Color(red: 0.62, green: 0.48, blue: 0.75)
        case 80..<95: return Color(red: 0.80, green: 0.45, blue: 0.45)
        default:      return Color(red: 0.52, green: 0.50, blue: 0.48)
        }
    }

    private var faceEmoji: String {
        switch score {
        case 0..<20:  return "✨"
        case 20..<40: return "♪"
        case 40..<60: return "📱"
        case 60..<80: return "😢"
        case 80..<95: return "🧠"
        default:      return "💀"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Kraken circle
            ZStack {
                Circle()
                    .fill(bodyColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [bodyColor, bodyColorDark],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: bodyColor.opacity(0.4), radius: 10, y: 4)

                // Simple face
                VStack(spacing: 4) {
                    Text(faceEmoji)
                        .font(.system(size: 32))
                }
            }

            // Tier badge
            HStack(spacing: 6) {
                Text(tierEmoji)
                    .font(.system(size: 18))
                Text(tierName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(tierColor.opacity(0.2))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(tierColor.opacity(0.4), lineWidth: 1.5)
            )

            // Streak
            if streakDays > 0 {
                HStack(spacing: 4) {
                    Text("\u{1F525}")
                        .font(.system(size: 16))
                    Text("\(streakDays)-day streak")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                }
            }

            // Branding
            VStack(spacing: 2) {
                Text("DoomScroll")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(BrainRotTheme.accentGradient)
                Text("Track your screen time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding(32)
        .frame(width: 300)
        .background(BrainRotTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(BrainRotTheme.cardBorder, lineWidth: 1.5)
        )
    }
}
