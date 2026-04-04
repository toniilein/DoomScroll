import SwiftUI

// MARK: - Usage bars rendered by the extension
// Apple's sandbox prevents passing data back to the native app.
// This rendered view IS the only way to show real usage.

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        if data.items.isEmpty {
            Color.clear.frame(height: 1)
        } else {
            VStack(spacing: 0) {
                // Section header
                HStack {
                    Text("Today's Usage")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.239, green: 0.224, blue: 0.161))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

                VStack(spacing: 10) {
                    ForEach(data.items, id: \.id) { item in
                        usageRow(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
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

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.957, green: 0.953, blue: 0.933))
                        .frame(width: 32, height: 32)
                    Image(systemName: iconForName(item.name))
                        .font(.system(size: 13))
                        .foregroundColor(textSecondary)
                }

                Text(item.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)

                Spacer()

                if exceeded {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("Exceeded")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                } else if usedMinutes > 0 {
                    Text("\(formatDuration(item.usedSeconds)) used \u{2022} \(formatDuration(remaining * 60)) left")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(textSecondary)
                } else {
                    Text("\(formatMinutes(item.limitMinutes)) remaining")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(textSecondary)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
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
