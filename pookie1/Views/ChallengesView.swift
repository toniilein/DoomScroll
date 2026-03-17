import SwiftUI

struct ChallengesView: View {
    @State private var score = SharedSettings.lastScore
    @State private var pickups = SharedSettings.lastPickups
    @State private var screenTimeMinutes = SharedSettings.lastScreenTimeMinutes
    @State private var streakDays = SharedSettings.streakDays
    @State private var bestStreak = SharedSettings.bestStreak
    @State private var streakHistory = SharedSettings.streakHistory

    @State private var fireScale: CGFloat = 1.0
    @State private var questProgress: [CGFloat] = [0, 0, 0]
    @State private var bubbleBounce: CGFloat = 0

    private var streakTier: StreakTier { .from(days: streakDays) }

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        krakenSpeechBubble
                        questBoard
                        streakBanner
                        streakCalendar
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

    // MARK: - Data

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
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            bubbleBounce = 4
        }

        let quests = dailyQuests
        for i in 0..<min(3, quests.count) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.15)) {
                questProgress[i] = CGFloat(quests[i].progress)
            }
        }
    }

    // MARK: - Kraken Speech Bubble

    private var krakenSpeech: String {
        let quests = dailyQuests
        let done = quests.filter { $0.isComplete }.count

        if done == 3 {
            return ["You're crushing it! I'm so happy!", "All quests done! You're my hero!", "Best. Human. Ever."].randomElement()!
        } else if done == 2 {
            return ["Almost there! One more quest!", "So close, don't stop now!"].randomElement()!
        } else if done == 1 {
            return ["Come on, I believe in you!", "We can do better together!"].randomElement()!
        } else if streakDays > 7 {
            return "We've been at this for \(streakDays) days... don't quit on me!"
        } else if streakDays > 0 {
            return "Let's keep the streak alive today!"
        } else {
            return "Hey! Let's start a streak together!"
        }
    }

    private var krakenMood: String {
        let done = dailyQuests.filter { $0.isComplete }.count
        switch done {
        case 3: return "\u{2728}"   // sparkles
        case 2: return "\u{1F60A}"  // smile
        case 1: return "\u{1F614}"  // pensive
        default: return "\u{1F630}" // anxious
        }
    }

    private var krakenSpeechBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            // Mini kraken face
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [krakenBodyColor, krakenBodyColor.opacity(0.7)],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: krakenBodyColor.opacity(0.3), radius: 6, y: 3)

                Text(krakenMood)
                    .font(.system(size: 22))
            }
            .offset(y: bubbleBounce)

            // Speech bubble
            VStack(alignment: .leading, spacing: 4) {
                Text(krakenSpeech)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                let done = dailyQuests.filter { $0.isComplete }.count
                Text("\(done)/3 quests complete")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(12)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BrainRotTheme.cardBorder, lineWidth: 1)
            )
        }
        .padding(.top, 4)
    }

    private var krakenBodyColor: Color {
        let done = dailyQuests.filter { $0.isComplete }.count
        switch done {
        case 3: return Color(red: 0.55, green: 0.88, blue: 0.70)  // mint (happy)
        case 2: return Color(red: 0.52, green: 0.82, blue: 0.78)  // seafoam
        case 1: return Color(red: 0.75, green: 0.62, blue: 0.88)  // lavender
        default: return Color(red: 0.92, green: 0.58, blue: 0.58) // coral (anxious)
        }
    }

    // MARK: - Quest Board

    private var questBoard: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "scroll.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BrainRotTheme.neonOrange)
                Text("Daily Quests")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Quest rows
            let quests = dailyQuests
            ForEach(Array(quests.enumerated()), id: \.element.id) { index, quest in
                questRow(quest: quest, index: index)

                if index < quests.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.cardBorder, lineWidth: 1)
        )
    }

    private func questRow(quest: Quest, index: Int) -> some View {
        HStack(spacing: 12) {
            // Mini ring
            ZStack {
                Circle()
                    .stroke(quest.color.opacity(0.15), lineWidth: 4)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: min(questProgress[index], 1.0))
                    .stroke(
                        quest.color,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                if quest.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(quest.color)
                } else {
                    Text(quest.emoji)
                        .font(.system(size: 16))
                }
            }

            // Quest info
            VStack(alignment: .leading, spacing: 2) {
                Text(quest.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(quest.isComplete ? BrainRotTheme.textSecondary : BrainRotTheme.textPrimary)
                    .strikethrough(quest.isComplete, color: BrainRotTheme.textSecondary)

                Text(quest.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            // Status
            if quest.isComplete {
                Text("DONE")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.neonGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BrainRotTheme.neonGreen.opacity(0.12))
                    .clipShape(Capsule())
            } else {
                Text("\(Int(quest.progress * 100))%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(quest.color)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        HStack(spacing: 10) {
            Text(streakTier.fireEmoji)
                .font(.system(size: 24))
                .scaleEffect(fireScale)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streakDays)-day streak")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)

                Text(streakMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if bestStreak > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                        .foregroundColor(BrainRotTheme.goldColor)
                    Text("\(bestStreak)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.goldColor)
                    Text("best")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(streakTier.color.opacity(streakDays > 0 ? 0.3 : 0.1), lineWidth: 1.5)
        )
    }

    // MARK: - Quest Data

    private var dailyQuests: [Quest] {
        let limit = SharedSettings.dailyLimitMinutes
        let halfLimit = limit / 2.0
        var quests: [Quest] = []

        // Quest 1: Score
        let scoreComplete = score < 50
        let scoreProgress = scoreComplete ? 1.0 : min(1.0, max(0, Double(100 - score) / 50.0))
        quests.append(Quest(
            emoji: "\u{1F3AF}", name: "Slay the Score",
            subtitle: scoreComplete ? "Score is under 50!" : "Get your score below 50",
            progress: scoreProgress, isComplete: scoreComplete,
            color: BrainRotTheme.neonGreen
        ))

        // Quest 2: Screen time
        let stGoal = halfLimit
        let stComplete = screenTimeMinutes <= stGoal
        let stProgress = screenTimeMinutes > 0 ? min(1.0, max(0, (stGoal - screenTimeMinutes) / stGoal)) : 1.0
        quests.append(Quest(
            emoji: "\u{23F1}\u{FE0F}", name: "Time Bandit",
            subtitle: stComplete ? "Under \(SharedSettings.formatLimit(stGoal))!" : "Stay under \(SharedSettings.formatLimit(stGoal))",
            progress: stProgress, isComplete: stComplete,
            color: BrainRotTheme.neonBlue
        ))

        // Quest 3: Pickups
        let pkGoal = 30
        let pkComplete = pickups <= pkGoal
        let pkProgress = pickups > 0 ? min(1.0, max(0, Double(pkGoal - pickups) / Double(pkGoal))) : 1.0
        quests.append(Quest(
            emoji: "\u{1F4F1}", name: "Hands Off!",
            subtitle: pkComplete ? "Under \(pkGoal) pickups!" : "Keep pickups under \(pkGoal)",
            progress: pkProgress, isComplete: pkComplete,
            color: BrainRotTheme.neonPurple
        ))

        return quests
    }

    // MARK: - Motivational Message

    private var streakMessage: String {
        if streakDays == 0 { return "Start your streak today!" }
        switch streakDays {
        case 1: return "Day 1 \u{2014} let's go!"
        case 2: return "2 days! Don't stop!"
        case 3: return "3 days \u{1F525} Building momentum!"
        case 4...6: return "\(streakDays) days! Getting stronger!"
        case 7: return "\u{1F389} ONE WEEK!"
        case 8...13: return "\(streakDays) days \u{2014} keep it up!"
        case 14: return "\u{1F3C6} TWO WEEKS!"
        case 15...29: return "\(streakDays) days \u{2014} unstoppable!"
        case 30: return "\u{1F451} 30 DAYS!"
        case 31...59: return "\(streakDays) days \u{2014} legend!"
        case 60...89: return "\u{1F48E} \(streakDays) days!"
        case 90...99: return "\u{1F680} \(streakDays) days!"
        case 100: return "\u{1F31F} 100 DAYS! GOAT!"
        default: return "\(streakDays) days \u{2014} untouchable"
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

// MARK: - Data Types

private struct Quest: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let subtitle: String
    let progress: Double
    let isComplete: Bool
    let color: Color
}

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
