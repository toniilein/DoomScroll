import SwiftUI

struct ChallengesView: View {
    @State private var score = SharedSettings.lastScore
    @State private var streakDays = SharedSettings.streakDays
    @State private var bestStreak = SharedSettings.bestStreak
    @State private var streakHistory = SharedSettings.streakHistory

    @State private var fireScale: CGFloat = 1.0
    @State private var ringProgress: CGFloat = 0

    private var ringClosed: Bool { score < 50 }
    private var streakTier: StreakTier { .from(days: streakDays) }

    private var ringColor: Color {
        if ringClosed { return BrainRotTheme.neonGreen }
        if score < 70 { return BrainRotTheme.neonBlue }
        if score < 85 { return BrainRotTheme.neonOrange }
        return BrainRotTheme.neonPink
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        dailyRingView
                        streakCalendar
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Challenges")
            .onAppear {
                refreshData()
                startAnimations()
            }
        }
    }

    // MARK: - Data

    private func refreshData() {
        score = SharedSettings.lastScore
        streakDays = SharedSettings.streakDays
        bestStreak = SharedSettings.bestStreak
        streakHistory = SharedSettings.streakHistory
        SharedSettings.recordStreakDay()
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            fireScale = 1.15
        }

        let target: CGFloat = ringClosed
            ? 1.0
            : CGFloat(min(1.0, max(0, Double(100 - score) / 50.0)))

        withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
            ringProgress = target
        }
    }

    // MARK: - The Ring

    private var dailyRingView: some View {
        VStack(spacing: 16) {
            // Ring
            ZStack {
                // Soft glow
                Circle()
                    .fill(ringColor.opacity(0.08))
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)

                // Background track
                Circle()
                    .stroke(ringColor.opacity(0.15), lineWidth: 18)
                    .frame(width: 200, height: 200)

                // Filled arc
                Circle()
                    .trim(from: 0, to: min(ringProgress, 1.0))
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                // Completion glow
                if ringClosed {
                    Circle()
                        .stroke(BrainRotTheme.neonGreen.opacity(0.3), lineWidth: 4)
                        .frame(width: 224, height: 224)
                        .blur(radius: 6)
                }

                // Center content
                VStack(spacing: 4) {
                    Text(streakTier.fireEmoji)
                        .font(.system(size: 32))
                        .scaleEffect(fireScale)

                    Text("\(streakDays)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)

                    Text(streakDays == 1 ? "day" : "days")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
            }
            .frame(height: 250)

            // Status
            if ringClosed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(BrainRotTheme.neonGreen)
                    Text("Ring Closed!")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.neonGreen)
                }
            } else {
                Text("Close your ring!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            // Motivational message
            Text(streakMessage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Best streak (subtle)
            if bestStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11))
                        .foregroundColor(BrainRotTheme.goldColor)
                    Text("Best: \(bestStreak) days")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Motivational Message

    private var streakMessage: String {
        if streakDays == 0 { return "Start your streak today!" }
        switch streakDays {
        case 1: return "Day 1 \u{2014} the hardest part is starting!"
        case 2: return "2 days in! Don't stop now!"
        case 3: return "3 days \u{1F525} Momentum is building!"
        case 4...6: return "\(streakDays) days! You're getting stronger!"
        case 7: return "\u{1F389} ONE WEEK! You're unstoppable!"
        case 8...13: return "\(streakDays) days \u{2014} don't throw it away!"
        case 14: return "\u{1F3C6} TWO WEEKS! This is serious!"
        case 15...20: return "\(streakDays) days \u{2014} imagine losing this..."
        case 21: return "3 WEEKS! You're a legend!"
        case 22...29: return "\(streakDays) days \u{2014} SO close to a month!"
        case 30: return "\u{1F451} 30 DAYS! KING STATUS!"
        case 31...59: return "\(streakDays) days \u{2014} you'd be crazy to quit now"
        case 60: return "\u{1F48E} 60 DAYS! Diamond hands!"
        case 61...89: return "\(streakDays) days \u{2014} don't you dare break this"
        case 90: return "\u{1F680} 90 DAYS! ABSOLUTE LEGEND!"
        case 91...99: return "\(streakDays) days \u{2014} triple digits is RIGHT THERE"
        case 100: return "\u{1F31F} 100 DAYS! YOU ARE THE GOAT!"
        default: return "\(streakDays) days \u{2014} nobody can touch you"
        }
    }

    // MARK: - Calendar

    private func formatDateISO(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private var streakCalendar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BrainRotTheme.neonOrange)
                Text("Last 28 Days")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            let dayLabels = [
                (0, "M"), (1, "T"), (2, "W"), (3, "T"), (4, "F"), (5, "S"), (6, "S")
            ]

            HStack(spacing: 4) {
                ForEach(dayLabels, id: \.0) { _, label in
                    Text(label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(BrainRotTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -27, to: calendar.startOfDay(for: .now))!
            let startWeekday = (calendar.component(.weekday, from: startDate) + 5) % 7

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<startWeekday, id: \.self) { idx in
                    Color.clear.frame(height: 30).id("pad-\(idx)")
                }

                ForEach(0..<28, id: \.self) { dayOffset in
                    let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
                    let dateStr = formatDateISO(date)
                    let isStreakDay = streakHistory.contains(dateStr)
                    let isToday = calendar.isDateInToday(date)
                    let isFuture = date > .now

                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                isFuture ? Color.clear :
                                isStreakDay ? streakTier.color.opacity(0.8) :
                                isToday ? BrainRotTheme.neonPink.opacity(0.15) :
                                BrainRotTheme.cardBorder.opacity(0.5)
                            )

                        if isStreakDay {
                            Text("\u{1F525}").font(.system(size: 13))
                        } else if isToday {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.neonPink)
                        } else if !isFuture {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }
                    }
                    .frame(height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isToday ? BrainRotTheme.neonPink.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Streak Tier

private enum StreakTier {
    case none, bronze, silver, gold, diamond, legendary

    static func from(days: Int) -> StreakTier {
        switch days {
        case 0: return .none
        case 1...6: return .bronze
        case 7...13: return .silver
        case 14...29: return .gold
        case 30...59: return .diamond
        default: return .legendary
        }
    }

    var fireEmoji: String {
        switch self {
        case .none: return "\u{1F9CA}"
        case .bronze: return "\u{1F525}"
        case .silver: return "\u{1F525}"
        case .gold: return "\u{1F525}"
        case .diamond: return "\u{1F48E}"
        case .legendary: return "\u{1F451}"
        }
    }

    var color: Color {
        switch self {
        case .none: return BrainRotTheme.textSecondary
        case .bronze: return BrainRotTheme.bronzeColor
        case .silver: return BrainRotTheme.silverColor
        case .gold: return BrainRotTheme.goldColor
        case .diamond: return BrainRotTheme.neonBlue
        case .legendary: return BrainRotTheme.neonPurple
        }
    }
}
