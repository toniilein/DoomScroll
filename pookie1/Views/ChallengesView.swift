import SwiftUI

struct ChallengesView: View {
    @State private var score = SharedSettings.lastScore
    @State private var pickups = SharedSettings.lastPickups
    @State private var screenTimeMinutes = SharedSettings.lastScreenTimeMinutes
    @State private var streakDays = SharedSettings.streakDays
    @State private var bestStreak = SharedSettings.bestStreak
    @State private var streakHistory = SharedSettings.streakHistory

    @State private var fireScale: CGFloat = 1.0
    @State private var fireGlow = false
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        streakHeroCard
                        streakCalendar
                        dailyChallengesCard
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
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

    private func refreshData() {
        score = SharedSettings.lastScore
        pickups = SharedSettings.lastPickups
        screenTimeMinutes = SharedSettings.lastScreenTimeMinutes
        streakDays = SharedSettings.streakDays
        bestStreak = SharedSettings.bestStreak
        streakHistory = SharedSettings.streakHistory
        SharedSettings.recordStreakDay()
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            fireScale = 1.15
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            fireGlow = true
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            ringProgress = todayProgress
        }
    }

    // MARK: - Helpers

    private var streakTier: StreakTier { .from(days: streakDays) }

    private var todayProgress: CGFloat {
        if score <= 0 { return 1.0 }
        if score >= 100 { return 0.0 }
        return CGFloat(max(0, min(1, Double(100 - score) / 100.0)))
    }

    private var fireSize: CGFloat {
        switch streakDays {
        case 0: return 34
        case 1...2: return 38
        case 3...6: return 42
        case 7...13: return 46
        case 14...29: return 50
        case 30...59: return 54
        default: return 58
        }
    }

    private var todayStatusEmoji: String {
        if score < 50 { return "\u{2705}" }
        if score < 70 { return "\u{26A0}\u{FE0F}" }
        return "\u{274C}"
    }

    private var daysToNextMilestone: Int {
        for m in streakMilestones {
            if streakDays < m.0 { return m.0 - streakDays }
        }
        return 365 - (streakDays % 365)
    }

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

    private func formatDateISO(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
            Spacer()
        }
    }

    // MARK: - Streak Hero Card

    private var streakHeroCard: some View {
        HStack(spacing: 16) {
            // Left: ring + streak count
            ZStack {
                Circle()
                    .stroke(BrainRotTheme.cardBorder, lineWidth: 5)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        streakTier.color,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(streakTier.fireEmoji)
                        .font(.system(size: 22))
                        .scaleEffect(fireScale)
                    Text("\(streakDays)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                }
            }

            // Right: tier + message + stats
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Text(streakTier.icon).font(.system(size: 11))
                    Text(streakTier.name)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(streakTier.color)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(streakTier.color.opacity(0.15))
                .clipShape(Capsule())

                Text(streakMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(bestStreak) best", systemImage: "trophy.fill")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(BrainRotTheme.goldColor)
                    Label("\(daysToNextMilestone)d to next", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(BrainRotTheme.neonBlue)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(streakTier.color.opacity(streakDays > 0 ? 0.3 : 0.1), lineWidth: 1.5)
        )
    }

    // MARK: - Streak Calendar

    private var streakCalendar: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "flame.fill", title: "Last 28 Days", color: BrainRotTheme.neonOrange)

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

    // MARK: - Daily Challenges

    private var dailyChallengesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "flag.checkered", title: "Today's Challenges", color: BrainRotTheme.neonPink)

            ForEach(dailyChallenges) { challenge in
                HStack(spacing: 12) {
                    Text(challenge.emoji).font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(challenge.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                            Spacer()
                            if challenge.isComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(BrainRotTheme.neonGreen)
                                    .font(.system(size: 14))
                            }
                        }
                        Text(challenge.description)
                            .font(.system(size: 11))
                            .foregroundColor(BrainRotTheme.textSecondary)
                        progressBar(
                            value: challenge.progress,
                            color: challenge.isComplete ? BrainRotTheme.neonGreen : BrainRotTheme.neonPink
                        )
                    }
                }
                .padding(.vertical, 4)

                if challenge.id != dailyChallenges.last?.id {
                    Divider().foregroundColor(BrainRotTheme.cardBorder)
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

    private var dailyChallenges: [Challenge] {
        let limit = SharedSettings.dailyLimitMinutes
        let halfLimit = limit / 2.0
        var challenges: [Challenge] = []

        if score > 50 {
            challenges.append(Challenge(
                emoji: "\u{1F3AF}", title: "Score Smasher",
                description: "Get your score below 50",
                progress: max(0, Double(100 - score) / 50.0), isComplete: false
            ))
        } else {
            challenges.append(Challenge(
                emoji: "\u{1F3AF}", title: "Score Smasher",
                description: "Keep your score below 50",
                progress: 1.0, isComplete: true
            ))
        }

        let screenTimeGoal = halfLimit
        let stProgress = screenTimeMinutes > 0 ? min(1.0, (screenTimeGoal - screenTimeMinutes) / screenTimeGoal) : 1.0
        challenges.append(Challenge(
            emoji: "\u{23F1}\u{FE0F}", title: "Half Day Hero",
            description: "Stay under \(SharedSettings.formatLimit(screenTimeGoal))",
            progress: max(0, stProgress), isComplete: screenTimeMinutes <= screenTimeGoal
        ))

        let pickupGoal = 30
        let pkProgress = pickups > 0 ? min(1.0, Double(pickupGoal - pickups) / Double(pickupGoal)) : 1.0
        challenges.append(Challenge(
            emoji: "\u{1F4F1}", title: "Phone Down",
            description: "Keep pickups under \(pickupGoal)",
            progress: max(0, pkProgress), isComplete: pickups <= pickupGoal
        ))

        return challenges
    }

    /// Reusable progress bar without GeometryReader to avoid layout overlap issues
    private func progressBar(value: Double, color: Color, height: CGFloat = 5) -> some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(BrainRotTheme.cardBorder)
            .frame(height: height)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(x: max(0, min(1, value)), y: 1, anchor: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: height / 2))
    }

}

// MARK: - Data

private let streakMilestones: [(Int, String, String)] = [
    (3, "\u{1F331}", "3-Day Starter"),
    (7, "\u{1F525}", "One Week Warrior"),
    (14, "\u{26A1}", "Two Week Tank"),
    (21, "\u{1F4AA}", "3-Week Beast"),
    (30, "\u{1F451}", "Monthly Master"),
    (60, "\u{1F48E}", "Diamond Hands"),
    (90, "\u{1F680}", "Quarter Legend"),
    (100, "\u{1F31F}", "Triple Digit God"),
    (365, "\u{1F3C6}", "YEAR KING"),
]

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

    var name: String {
        switch self {
        case .none: return "No Streak"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .diamond: return "Diamond"
        case .legendary: return "Legendary"
        }
    }

    var icon: String {
        switch self {
        case .none: return "\u{26AA}"
        case .bronze: return "\u{1F7E4}"
        case .silver: return "\u{26AA}"
        case .gold: return "\u{1F7E1}"
        case .diamond: return "\u{1F48E}"
        case .legendary: return "\u{1F451}"
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

private struct Challenge: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    let progress: Double
    let isComplete: Bool
}

