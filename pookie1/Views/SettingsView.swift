import SwiftUI

struct SettingsView: View {
    @State private var dailyLimitMinutes: Double = SharedSettings.dailyLimitMinutes

    // Slider steps: 30, 60, 90, 120, 180, 240, 300, 360, 420, 480
    private let minLimit: Double = 30
    private let maxLimit: Double = 480

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Daily Limit Card
                        dailyLimitCard

                        // Score Preview
                        scorePreviewCard

                        // About
                        aboutCard
                    }
                    .padding()
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Daily Limit

    private var dailyLimitCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("Daily Limit")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text(SharedSettings.formatLimit(dailyLimitMinutes))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.neonPink)
            }

            Text("Your personal daily screen time goal. The brainrot score scales to this limit.")
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)

            Slider(
                value: $dailyLimitMinutes,
                in: minLimit...maxLimit,
                step: 30
            )
            .tint(BrainRotTheme.neonPink)
            .onChange(of: dailyLimitMinutes) { _, newValue in
                SharedSettings.dailyLimitMinutes = newValue
            }

            // Limit labels
            HStack {
                Text("30m")
                    .font(.caption2)
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                Text("8h")
                    .font(.caption2)
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Score Preview

    private var scorePreviewCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(BrainRotTheme.neonBlue)
                Text("Score Preview")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            Text("How your score changes with \(SharedSettings.formatLimit(dailyLimitMinutes)) daily limit:")
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)

            VStack(spacing: 8) {
                scoreRow(label: "30m", minutes: 30)
                scoreRow(label: "1h", minutes: 60)
                scoreRow(label: "2h", minutes: 120)
                scoreRow(label: "4h", minutes: 240)
                scoreRow(label: "6h", minutes: 360)
                scoreRow(label: "8h", minutes: 480)
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func scoreRow(label: String, minutes: Double) -> some View {
        let limit = dailyLimitMinutes
        let ratio = minutes / limit
        let score: Int = {
            if ratio <= 0.5 {
                return Int(ratio * 2.0 * 30.0)
            } else if ratio <= 1.0 {
                return Int(30.0 + (ratio - 0.5) * 2.0 * 35.0)
            } else if ratio <= 1.5 {
                return Int(65.0 + (ratio - 1.0) * 2.0 * 20.0)
            } else if ratio <= 2.0 {
                return Int(85.0 + (ratio - 1.5) * 2.0 * 10.0)
            } else {
                return min(99, Int(95.0 + (ratio - 2.0) * 2.0))
            }
        }()

        return HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)
                .frame(width: 40, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BrainRotTheme.scoreColor(for: score))
                        .frame(width: max(0, geo.size.width * CGFloat(min(99, score)) / 99.0), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(score)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.scoreColor(for: score))
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(BrainRotTheme.neonGreen)
                Text("How Scoring Works")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                infoRow(pct: "0-50%", range: "0-30", desc: "Healthy zone")
                infoRow(pct: "50-100%", range: "30-65", desc: "Getting there")
                infoRow(pct: "100-150%", range: "65-85", desc: "Over your limit")
                infoRow(pct: "150-200%", range: "85-95", desc: "Deep brainrot")
                infoRow(pct: "200%+", range: "95-99", desc: "Terminal")
            }

            Text("Score is based on % of your daily limit used. It never hits 100 so there's always room to improve (or get worse).")
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(pct: String, range: String, desc: String) -> some View {
        HStack {
            Text(pct)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)
                .frame(width: 70, alignment: .leading)
            Text("Score \(range)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            Text(desc)
                .font(.system(size: 12))
                .foregroundColor(BrainRotTheme.textSecondary)
            Spacer()
        }
    }
}
