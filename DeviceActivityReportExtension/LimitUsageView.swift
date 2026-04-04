import SwiftUI

// MARK: - Compact usage bars rendered by extension
// This is the ONLY way to show real usage data — the extension can read
// DeviceActivityResults but cannot pass data back to the native app.

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        if data.items.isEmpty {
            Color.clear.frame(height: 1)
        } else {
            VStack(spacing: 8) {
                ForEach(data.items, id: \.id) { item in
                    usageRow(item)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.957, green: 0.953, blue: 0.933))
        }
    }

    private func usageRow(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))
        let remaining = max(0, Double(item.limitMinutes) - usedMinutes)

        let textPrimary = Color(red: 0.239, green: 0.224, blue: 0.161)
        let textSecondary = Color(red: 0.549, green: 0.522, blue: 0.467)
        let barTrack = Color(red: 0.910, green: 0.898, blue: 0.863)
        let purple = Color(red: 0.608, green: 0.420, blue: 0.769)

        return VStack(spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)

                Spacer()

                if exceeded {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("\(formatDuration(item.usedSeconds)) used")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                } else {
                    Text("\(formatDuration(item.usedSeconds)) / \(formatMinutes(item.limitMinutes))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(usedMinutes > 0 ? textPrimary : textSecondary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barTrack)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(exceeded ? Color.red : purple)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
