import SwiftUI

// MARK: - Usage bars rendered by extension, placed under each limit card
// Apple's sandbox prevents passing data back to native app.
// This rendered view IS the only way to show real usage.

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        if data.items.isEmpty {
            Color.clear.frame(height: 1)
        } else {
            VStack(spacing: 0) {
                // "Today's Usage" label
                HStack {
                    Text(L("limitEditor.todayUsage"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                    Spacer()
                }
                .padding(.bottom, 8)

                VStack(spacing: 12) {
                    ForEach(data.items, id: \.id) { item in
                        usageBar(item)
                    }
                }
            }
            .padding(.horizontal, 0)
            .preferredColorScheme(SharedTheme.colorScheme)
        }
    }

    private func usageBar(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))
        let remaining = max(0, Double(item.limitMinutes) - usedMinutes)

        let textPrimary = BrainRotTheme.textPrimary
        let textSecondary = BrainRotTheme.textSecondary
        let barTrack = BrainRotTheme.cardBorder
        let purple = BrainRotTheme.neonPurple

        return VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(BrainRotTheme.background)
                            .frame(width: 28, height: 28)
                        Image(systemName: iconForName(item.name))
                            .font(.system(size: 11))
                            .foregroundColor(textSecondary)
                    }

                    Text(item.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                if exceeded {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("\(formatDuration(item.usedSeconds)) / \(formatMinutes(item.limitMinutes))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                } else if usedMinutes > 0 {
                    Text("\(formatDuration(item.usedSeconds)) / \(formatMinutes(item.limitMinutes))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(purple)
                } else {
                    Text("0m / \(formatMinutes(item.limitMinutes))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(textSecondary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barTrack)
                    if progress > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(exceeded ? Color.red : purple)
                            .frame(width: max(4, geo.size.width * progress))
                    }
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(BrainRotTheme.cardBackground)
    }

    // MARK: - Helpers

    private func iconForName(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("all") { return "square.grid.2x2" }
        if l.contains("social") { return "arrowshape.turn.up.right" }
        if l.contains("game") || l.contains("gaming") { return "gamecontroller" }
        if l.contains("entertainment") || l.contains("video") || l.contains("stream") { return "play.tv" }
        if l.contains("news") || l.contains("read") { return "newspaper" }
        if l.contains("shop") || l.contains("buy") { return "cart" }
        if l.contains("message") || l.contains("chat") { return "message" }
        if l.contains("music") || l.contains("audio") { return "music.note" }
        return "square.grid.2x2"
    }

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
