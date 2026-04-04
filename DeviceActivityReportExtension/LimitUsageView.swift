import SwiftUI

// MARK: - Extension-rendered usage cards
// Matches the native limit card style: icon circle, name, usage subtitle.
// Fixed card height so native overlay can align toggles on top.
// Card: 76pt. Spacing: 12pt. Padding: 0pt (native handles outer padding).

struct LimitUsageView: View {
    let data: LimitUsageData

    static let cardHeight: CGFloat = 76
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
        let remaining = max(0, Double(item.limitMinutes) - usedMinutes)

        return ZStack {
            Color.white

            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(Color(red: 0.957, green: 0.953, blue: 0.933)) // BrainRotTheme.background
                        .frame(width: 48, height: 48)
                    Image(systemName: iconForName(item.name))
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.549, green: 0.522, blue: 0.467)) // textSecondary
                }

                // Name + usage info
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.239, green: 0.224, blue: 0.161)) // textPrimary
                        .lineLimit(1)

                    if exceeded {
                        Text("\(formatMinutes(item.limitMinutes)) limit \u{2022} \(formatDuration(item.usedSeconds)) used \u{2022} Exceeded")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.red)
                            .lineLimit(1)
                    } else {
                        Text("\(formatMinutes(item.limitMinutes)) limit \u{2022} \(formatDuration(remaining * 60)) remaining")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.549, green: 0.522, blue: 0.467)) // textSecondary
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Reserve space for native toggle overlay (~56pt)
                Color.clear.frame(width: 56, height: 1)
            }
            .padding(.horizontal, 18)
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
