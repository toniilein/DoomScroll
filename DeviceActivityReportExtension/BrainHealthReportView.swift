import SwiftUI

struct BrainHealthReportView: View {
    let healthData: BrainHealthData

    var body: some View {
        VStack(spacing: 24) {
            // Score header
            VStack(spacing: 8) {
                Text("YOUR DOOMSCROLL SCORE")
                    .font(.caption.bold())
                    .foregroundColor(BrainRotTheme.textSecondary)
                    .tracking(2)

                BrainRotScoreView(
                    score: healthData.brainRotScore,
                    totalScreenTime: healthData.formattedDuration
                )

                Text(BrainRotTheme.scoreEmoji(for: healthData.brainRotScore))
                    .font(.system(size: 32))
            }
            .padding(.top, 8)

            // Health bar
            healthStatusSection

            // Metrics grid
            metricsSection

            // Top doomscroll apps
            if !healthData.topApps.isEmpty {
                topDoomscrollApps
            }

            // Tip
            tipSection
        }
        .padding()
        .background(BrainRotTheme.background)
    }

    private var healthStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .font(.title2)
                    .foregroundColor(BrainRotTheme.neonPink)
                Text("Brain Health Status")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(healthBarColor(index: i))
                        .frame(height: 8)
                        .clipShape(
                            .rect(
                                topLeadingRadius: i == 0 ? 4 : 0,
                                bottomLeadingRadius: i == 0 ? 4 : 0,
                                bottomTrailingRadius: i == 4 ? 4 : 0,
                                topTrailingRadius: i == 4 ? 4 : 0
                            )
                        )
                }
            }

            HStack {
                Text("Healthy")
                    .font(.caption2)
                    .foregroundColor(BrainRotTheme.neonGreen)
                Spacer()
                Text("Cooked")
                    .font(.caption2)
                    .foregroundColor(BrainRotTheme.neonPink)
            }

            Text(healthAdvice)
                .font(.subheadline)
                .foregroundColor(BrainRotTheme.textSecondary)
                .padding(.top, 4)
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.scoreColor(for: healthData.brainRotScore).opacity(0.3), lineWidth: 1)
        )
    }

    private var metricsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("Doomscroll Metrics")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            HStack(spacing: 12) {
                StatsCardView(
                    title: "Pickups",
                    value: "\(healthData.totalPickups)",
                    icon: "iphone.gen3",
                    color: BrainRotTheme.neonPurple
                )
                StatsCardView(
                    title: "Longest Session",
                    value: "\(healthData.longestSessionMinutes)m",
                    icon: "timer",
                    color: BrainRotTheme.neonPink
                )
            }
        }
    }

    private var topDoomscrollApps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Doomscroll Apps")
                .font(.headline)
                .foregroundColor(BrainRotTheme.textPrimary)

            ForEach(Array(healthData.topApps.enumerated()), id: \.element.id) { index, app in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(BrainRotTheme.textSecondary)
                        .frame(width: 20)

                    Text(app.displayName)
                        .font(.body.bold())
                        .foregroundColor(BrainRotTheme.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(app.formattedDuration)
                        .font(.body.bold())
                        .foregroundColor(BrainRotTheme.scoreColor(for: BrainRotCalculator.score(totalMinutes: app.duration / 60.0)))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(BrainRotTheme.cardBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var tipSection: some View {
        HStack(spacing: 12) {
            Text("\u{1F4A1}")
                .font(.title3)
            Text(currentTip)
                .font(.subheadline)
                .foregroundColor(BrainRotTheme.textSecondary)
            Spacer()
        }
        .padding()
        .background(BrainRotTheme.neonGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func healthBarColor(index: Int) -> Color {
        let filledSegments = healthData.brainRotScore / 20
        if index < filledSegments {
            switch index {
            case 0: return BrainRotTheme.neonGreen
            case 1: return BrainRotTheme.neonBlue
            case 2: return BrainRotTheme.neonPurple
            case 3: return BrainRotTheme.neonPink
            default: return BrainRotTheme.neonPink
            }
        } else if index == filledSegments {
            return BrainRotTheme.neonPurple.opacity(0.4)
        }
        return Color.white.opacity(0.1)
    }

    private var healthAdvice: String {
        switch healthData.brainRotScore {
        case 0..<30:
            return "Your brain is thriving! Keep up the healthy screen habits."
        case 30..<60:
            return "Not bad, but watch out for those scrolling sessions creeping up."
        case 60..<80:
            return "Your screen time is above average. Consider taking more breaks."
        default:
            return "Full brainrot detected. Time to put the phone down and touch grass."
        }
    }

    private var currentTip: String {
        switch healthData.brainRotScore {
        case 0..<30:
            return "You're doing great! Try to maintain this balance."
        case 30..<60:
            return "Try a 15-minute phone-free walk after lunch."
        case 60..<80:
            return "Set app time limits for your top doomscroll apps."
        default:
            return "Challenge: Can you go 1 hour without checking your phone?"
        }
    }
}
