import SwiftUI

// MARK: - Extension-rendered usage view: categories + per-limit usage

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Total screen time today
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(BrainRotTheme.neonOrange)
                Text("Today: \(formatDuration(data.totalDuration))")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            // Per-category usage
            if !data.categories.isEmpty {
                VStack(spacing: 4) {
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
                        .padding(.horizontal, 14)
                    }
                }
            }

            // Per-limit usage (if limits configured)
            if !data.items.isEmpty {
                Divider().padding(.horizontal, 14)

                VStack(spacing: 6) {
                    ForEach(data.items, id: \.id) { item in
                        limitRow(item)
                    }
                }
            }

            Spacer().frame(height: 6)
        }
    }

    private func limitRow(_ item: LimitUsageItem) -> some View {
        let usedMinutes = item.usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(item.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, item.limitMinutes)))

        return VStack(spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .font(.system(size: 11))
                    .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)
                    .frame(width: 16)
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                    .lineLimit(1)
                Spacer()
                Text(formatDuration(item.usedSeconds))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)
                Text("/ \(formatMinutes(item.limitMinutes))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                if exceeded {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 14)

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
            .padding(.horizontal, 14)
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
        if l.contains("travel") { return "car.fill" }
        if l.contains("finance") || l.contains("business") { return "dollarsign.circle.fill" }
        if l.contains("weather") { return "cloud.sun.fill" }
        if l.contains("utilit") { return "wrench.fill" }
        if l.contains("information") || l.contains("reference") { return "info.circle.fill" }
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
