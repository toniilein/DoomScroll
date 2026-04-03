import SwiftUI

// MARK: - Extension-rendered usage cards
// Each card has a FIXED height so the native overlay can align controls on top.
// Card height: 68pt content. Spacing: 8pt. Padding: 8pt top/bottom.

struct LimitUsageView: View {
    let data: LimitUsageData

    static let cardHeight: CGFloat = 68
    static let cardSpacing: CGFloat = 8
    static let verticalPadding: CGFloat = 8

    var body: some View {
        VStack(spacing: Self.cardSpacing) {
            ForEach(data.items, id: \.id) { item in
                limitRow(item)
                    .frame(height: Self.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, Self.verticalPadding)
    }

    private func limitRow(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))

        return ZStack {
            BrainRotTheme.cardBackground

            VStack(spacing: 0) {
                // Row 1: name + usage text (leave right space for native toggle)
                HStack {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(formatDuration(item.usedSeconds)) / \(formatMinutes(item.limitMinutes))")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)

                    // Reserve space for native toggle overlay
                    Color.clear.frame(width: 56, height: 1)
                }

                Spacer().frame(height: 8)

                // Row 2: progress bar
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

                // Row 3: exceeded or status text
                if exceeded {
                    Spacer().frame(height: 6)
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("Limit exceeded — apps blocked")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(.red)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
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
