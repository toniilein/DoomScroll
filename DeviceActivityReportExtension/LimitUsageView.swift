import SwiftUI

// MARK: - Extension-rendered usage cards (compact, one row per limit)

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        VStack(spacing: 8) {
            ForEach(data.items, id: \.id) { item in
                limitRow(item)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func limitRow(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))

        return VStack(spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("\(formatDuration(item.usedSeconds)) / \(formatMinutes(item.limitMinutes))")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(BrainRotTheme.cardBorder)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(exceeded ? Color.red : BrainRotTheme.neonOrange)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)

            if exceeded {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text("Limit exceeded")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Detail view (kept for extension registration)

struct LimitUsageDetailView: View {
    let data: LimitUsageDetailData

    var body: some View {
        Color.clear.frame(height: 1)
    }
}
