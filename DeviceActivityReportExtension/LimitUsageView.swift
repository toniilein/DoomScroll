import SwiftUI

// MARK: - Extension-rendered usage cards
// Matches the native limit card style: icon circle, name, usage subtitle, progress bar.
// Fixed card height so native overlay can align toggles on top.
// Card: 90pt. Spacing: 12pt.

struct LimitUsageView: View {
    let data: LimitUsageData

    static let cardHeight: CGFloat = 90
    static let cardSpacing: CGFloat = 12

    var body: some View {
        VStack(spacing: Self.cardSpacing) {
            ForEach(data.items, id: \.id) { item in
                limitCard(item)
                    .frame(height: Self.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(.horizontal, 20)
    }

    private func limitCard(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))
        let remaining = max(0, Double(item.limitMinutes) - usedMinutes)

        let textPrimary = Color(red: 0.239, green: 0.224, blue: 0.161)
        let textSecondary = Color(red: 0.549, green: 0.522, blue: 0.467)
        let bgColor = Color(red: 0.957, green: 0.953, blue: 0.933)
        let barTrack = Color(red: 0.910, green: 0.898, blue: 0.863)
        let purple = Color(red: 0.608, green: 0.420, blue: 0.769)

        return ZStack {
            Color.white

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(bgColor)
                            .frame(width: 44, height: 44)
                        Image(systemName: iconForName(item.name))
                            .font(.system(size: 16))
                            .foregroundColor(textSecondary)
                    }

                    // Name + usage info
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(textPrimary)
                            .lineLimit(1)

                        if exceeded {
                            Text("\(formatMinutes(item.limitMinutes)) limit \u{2022} \(formatDuration(item.usedSeconds)) used \u{2022} Exceeded")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.red)
                                .lineLimit(1)
                        } else {
                            Text("\(formatMinutes(item.limitMinutes)) limit \u{2022} \(formatDuration(remaining * 60)) remaining")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Reserve space for native toggle overlay
                    Color.clear.frame(width: 56, height: 1)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 0)

                // Progress bar at bottom
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barTrack)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(exceeded ? Color.red : purple)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .padding(.top, 14)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
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
