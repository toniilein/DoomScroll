import SwiftUI

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        VStack(spacing: 6) {
            // Usage text
            HStack {
                Text(data.formattedDuration)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(data.exceeded ? .red : BrainRotTheme.neonOrange)

                Text("/ \(formatMins(Double(data.limitMinutes)))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)

                Spacer()

                if data.exceeded {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("Blocked")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                }
            }

            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(BrainRotTheme.cardBorder)
                    .frame(height: 6)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: data.exceeded
                                    ? [.red, .red.opacity(0.7)]
                                    : [BrainRotTheme.neonOrange, BrainRotTheme.neonOrange.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * data.progress, height: 6)
                }
                .frame(height: 6)
            }
        }
    }

    private func formatMins(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        if m > 0 { return "\(m)m" }
        return "0m"
    }
}
