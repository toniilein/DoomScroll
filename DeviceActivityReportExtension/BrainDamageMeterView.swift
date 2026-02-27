import SwiftUI

struct BrainDamageMeterView: View {
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrainRotTheme.neonPink)
                Text("Brain Damage Meter")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            // Gradient bar with skull at end
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 16)

                        // Filled gradient
                        RoundedRectangle(cornerRadius: 8)
                            .fill(BrainRotTheme.brainDamageGradient)
                            .frame(
                                width: max(0, geo.size.width * CGFloat(min(100, score)) / 100.0),
                                height: 16
                            )

                        // Indicator dot at position
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                            .offset(
                                x: max(5, geo.size.width * CGFloat(min(100, score)) / 100.0 - 5)
                            )
                    }
                }
                .frame(height: 16)

                Text("\u{1F480}")
                    .font(.system(size: 18))
            }

            // Labels
            HStack {
                Text("\u{1F9D8} Healthy")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(BrainRotTheme.neonGreen)
                Spacer()
                Text("Cooked \u{1F525}")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(BrainRotTheme.neonPink)
            }
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
