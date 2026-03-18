import SwiftUI

struct UsageSummaryView: View {
    let data: UsageSummaryData

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 11))
                    .foregroundColor(BrainRotTheme.neonOrange)
                Text("Today: \(data.formattedDuration)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            if !data.categories.isEmpty {
                ForEach(Array(data.categories.prefix(6))) { cat in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(BrainRotTheme.neonOrange.opacity(0.4))
                            .frame(width: 6, height: 6)
                        Text(cat.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(cat.formattedDuration)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
