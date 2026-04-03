import SwiftUI

// MARK: - Extension-rendered usage cards (one per limit, shown under native limit cards)

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        VStack(spacing: 10) {
            // Per-limit usage cards
            ForEach(data.items, id: \.id) { item in
                limitUsageCard(item)
            }

            // Category breakdown
            if !data.categories.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BrainRotTheme.neonOrange)
                        Text("Today's Usage")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textSecondary)
                        Spacer()
                        Text(formatDuration(data.totalDuration))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)
                    }

                    ForEach(Array(data.categories.prefix(8).enumerated()), id: \.offset) { _, cat in
                        HStack(spacing: 8) {
                            Image(systemName: categoryIcon(cat.name))
                                .font(.system(size: 11))
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .frame(width: 16)
                            Text(cat.name)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text(formatDuration(cat.duration))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                        }
                    }
                }
                .padding(14)
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func limitUsageCard(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))

        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.isEnabled ? BrainRotTheme.neonOrange.opacity(0.15) : BrainRotTheme.cardBorder)
                        .frame(width: 42, height: 42)
                    Image(systemName: iconFor(item.name))
                        .font(.system(size: 18))
                        .foregroundColor(item.isEnabled ? BrainRotTheme.neonOrange : BrainRotTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)

                    HStack(spacing: 4) {
                        Text(formatDuration(item.usedSeconds))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)

                        Text("/ \(formatMinutes(item.limitMinutes))")
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
                }

                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BrainRotTheme.cardBorder)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(exceeded ? Color.red : BrainRotTheme.neonOrange)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

    private func iconFor(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("social") { return "person.2.fill" }
        if l.contains("game") || l.contains("gaming") { return "gamecontroller.fill" }
        if l.contains("entertainment") || l.contains("video") || l.contains("stream") { return "play.tv.fill" }
        if l.contains("news") || l.contains("read") { return "newspaper.fill" }
        if l.contains("shop") || l.contains("buy") { return "cart.fill" }
        if l.contains("product") || l.contains("work") { return "briefcase.fill" }
        if l.contains("message") || l.contains("chat") { return "message.fill" }
        if l.contains("music") || l.contains("audio") { return "music.note" }
        if l.contains("photo") || l.contains("camera") { return "camera.fill" }
        return "hourglass"
    }

    private func categoryIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("social") { return "person.2.fill" }
        if l.contains("game") { return "gamecontroller.fill" }
        if l.contains("entertainment") { return "play.tv.fill" }
        if l.contains("productiv") { return "briefcase.fill" }
        if l.contains("education") { return "book.fill" }
        if l.contains("health") { return "heart.fill" }
        if l.contains("news") || l.contains("read") { return "newspaper.fill" }
        if l.contains("shopping") { return "cart.fill" }
        if l.contains("music") { return "music.note" }
        if l.contains("photo") || l.contains("video") { return "camera.fill" }
        if l.contains("utilit") { return "wrench.fill" }
        return "app.fill"
    }
}

// MARK: - Detail view (kept for extension registration)

struct LimitUsageDetailView: View {
    let data: LimitUsageDetailData

    var body: some View {
        Color.clear.frame(height: 1)
    }
}
