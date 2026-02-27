import SwiftUI

struct QuickStatsRowView: View {
    let pickups: Int
    let avgSessionMinutes: Double
    let pickupFrequencyMinutes: Double

    var body: some View {
        HStack(spacing: 8) {
            quickStat(
                icon: "iphone.gen3",
                value: "\(pickups)",
                label: "Pickups",
                color: BrainRotTheme.neonPurple
            )

            quickStat(
                icon: "timer",
                value: "\(Int(avgSessionMinutes))m",
                label: "Avg Session",
                color: BrainRotTheme.neonBlue
            )

            quickStat(
                icon: "hand.tap.fill",
                value: "\(Int(pickupFrequencyMinutes))m",
                label: "Frequency",
                color: BrainRotTheme.neonPink
            )
        }
    }

    private func quickStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
