import SwiftUI

struct MetricsGridView: View {
    let addictionIndex: Double
    let pickupsPerHour: Double
    let longestSessionMinutes: Int
    let focusDestroyerApp: String
    let focusDestroyerPickups: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                metricCard(
                    icon: "bolt.heart.fill",
                    title: "Addiction Index",
                    value: String(format: "%.1f", addictionIndex),
                    subtitle: BrainRotCalculator.addictionIndexLabel(addictionIndex),
                    color: addictionColor
                )

                metricCard(
                    icon: "hand.tap.fill",
                    title: "Pickups/Hour",
                    value: String(format: "%.1f", pickupsPerHour),
                    subtitle: pickupsPerHour > 4 ? "That's a lot" : "Not bad",
                    color: BrainRotTheme.neonPurple
                )
            }

            HStack(spacing: 8) {
                metricCard(
                    icon: "timer",
                    title: "Longest Binge",
                    value: "\(longestSessionMinutes)m",
                    subtitle: longestSessionMinutes > 60 ? "Impressive (bad)" : "Moderate",
                    color: BrainRotTheme.neonPink
                )

                metricCard(
                    icon: "eye.trianglebadge.exclamationmark",
                    title: "Focus Destroyer",
                    value: focusDestroyerApp.count > 10
                        ? String(focusDestroyerApp.prefix(9)) + ".."
                        : focusDestroyerApp,
                    subtitle: "\(focusDestroyerPickups) pickups",
                    color: BrainRotTheme.neonOrange
                )
            }
        }
    }

    private func metricCard(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
            }

            HStack {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
            }

            HStack {
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                Spacer()
            }
        }
        .padding(12)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private var addictionColor: Color {
        switch addictionIndex {
        case ..<5: return BrainRotTheme.neonGreen
        case 5..<15: return BrainRotTheme.neonBlue
        case 15..<30: return BrainRotTheme.neonPurple
        default: return BrainRotTheme.neonPink
        }
    }
}
