import SwiftUI

// MARK: - Compact usage labels rendered by extension (has real usage data)

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        VStack(spacing: 6) {
            ForEach(data.items, id: \.id) { item in
                limitUsageLabel(item)
            }
        }
    }

    private func limitUsageLabel(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))

        let h = Int(usedMinutes) / 60
        let m = Int(usedMinutes) % 60
        let formatted: String = {
            if h > 0 && m > 0 { return "\(h)h \(m)m" }
            if h > 0 { return "\(h)h" }
            return "\(m)m"
        }()

        let limitH = item.limitMinutes / 60
        let limitM = item.limitMinutes % 60
        let limitFormatted: String = {
            if limitH > 0 && limitM > 0 { return "\(limitH)h \(limitM)m" }
            if limitH > 0 { return "\(limitH)h" }
            return "\(limitM)m"
        }()

        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Text(formatted)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)

                Text("/ \(limitFormatted)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)

                if exceeded {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                        Text("Exceeded")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                }
            }

            // Thin progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BrainRotTheme.cardBorder)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(exceeded ? Color.red : BrainRotTheme.neonOrange)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

// MARK: - Detail view (kept for extension registration)

struct LimitUsageDetailView: View {
    let data: LimitUsageDetailData

    var body: some View {
        Color.clear.frame(height: 1)
    }
}
