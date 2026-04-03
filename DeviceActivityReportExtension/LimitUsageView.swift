import SwiftUI

// MARK: - Renders actual limit cards with usage data from the extension

struct LimitUsageView: View {
    let data: LimitUsageData

    var body: some View {
        VStack(spacing: 10) {
            ForEach(data.items, id: \.id) { item in
                limitItemCard(item)
            }

            if data.items.isEmpty {
                Color.clear.frame(height: 2)
            }
        }
    }

    private func limitItemCard(_ item: LimitUsageItem) -> some View {
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

        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.isEnabled ? BrainRotTheme.neonOrange.opacity(0.15) : BrainRotTheme.cardBorder)
                        .frame(width: 40, height: 40)
                    Image(systemName: iconFor(item.name))
                        .font(.system(size: 17))
                        .foregroundColor(item.isEnabled ? BrainRotTheme.neonOrange : BrainRotTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)

                    HStack(spacing: 4) {
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
                            .padding(.leading, 2)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BrainRotTheme.textSecondary.opacity(0.5))
            }

            // Progress bar
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
}

// MARK: - Detail view (kept for extension registration)

struct LimitUsageDetailView: View {
    let data: LimitUsageDetailData

    var body: some View {
        Color.clear.frame(height: 1)
    }
}
