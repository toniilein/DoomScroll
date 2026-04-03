import SwiftUI

// MARK: - Compact summary for Shield tab (single report for all limits)

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        VStack(spacing: 4) {
        Text(data.debugInfo)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.orange)
            .fixedSize(horizontal: false, vertical: true)
            .padding(6)
            .background(Color.orange.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))

        if data.exceededCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                Text("\(data.exceededCount) limit\(data.exceededCount == 1 ? "" : "s") exceeded")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else if data.activeCount > 0 {
            Text("\(data.activeCount) limit\(data.activeCount == 1 ? "" : "s") active")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)
                .frame(height: 4)
                .opacity(0.01)
        } else {
            Color.clear.frame(height: 2)
        }
        } // VStack
    }
}

// MARK: - Detail view for Editor sheet

struct LimitUsageDetailView: View {
    let data: LimitUsageDetailData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(data.formattedDuration)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(data.exceeded ? .red : BrainRotTheme.neonOrange)

                Text("/ \(formatMins(data.limitMinutes))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)

                Spacer()

                if data.exceeded {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text("Exceeded")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(BrainRotTheme.cardBorder)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: data.exceeded
                                    ? [.red, .red.opacity(0.7)]
                                    : [BrainRotTheme.neonOrange, BrainRotTheme.neonOrange.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * data.progress)
                }
            }
            .frame(height: 6)

            let activeCats = data.categories.filter { $0.duration > 0 }
            if !activeCats.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(activeCats.enumerated()), id: \.offset) { _, cat in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(BrainRotTheme.neonOrange.opacity(0.6))
                                .frame(width: 6, height: 6)
                            Text(cat.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text(cat.formattedDuration)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func formatMins(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
