import SwiftUI

struct DoomRatioView: View {
    let appName: String
    let percentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(BrainRotTheme.neonOrange)
                Text("Doom Ratio")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(percentageColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(BrainRotTheme.cardBorder)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [BrainRotTheme.neonPurple, BrainRotTheme.neonPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * min(1, percentage / 100.0)), height: 12)
                }
            }
            .frame(height: 12)

            Text("\(appName) is eating \(Int(percentage))% of your brain")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)
                .italic()
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var percentageColor: Color {
        switch percentage {
        case ..<30: return BrainRotTheme.neonGreen
        case 30..<60: return BrainRotTheme.neonBlue
        case 60..<80: return BrainRotTheme.neonPurple
        default: return BrainRotTheme.neonPink
        }
    }
}
