import SwiftUI

struct ChallengesView: View {
    @State private var score = SharedSettings.lastScore
    @State private var pickups = SharedSettings.lastPickups
    @State private var screenTimeMinutes = SharedSettings.lastScreenTimeMinutes
    @State private var streakDays = SharedSettings.streakDays
    @State private var bestStreak = SharedSettings.bestStreak
    @State private var streakHistory = SharedSettings.streakHistory

    @State private var fireScale: CGFloat = 1.0

    // Ring animation states
    @State private var scoreRingProgress: CGFloat = 0
    @State private var screenTimeRingProgress: CGFloat = 0
    @State private var pickupsRingProgress: CGFloat = 0
    @State private var selectedRing: RingType? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        activityRingsCard
                        streakRow
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
        // Fire pulse
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            fireScale = 1.15
        }

        // Staggered ring fill — outer first, inner last
        let challenges = dailyChallenges
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            scoreRingProgress = CGFloat(challenges[0].progress)
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
            screenTimeRingProgress = CGFloat(challenges[1].progress)
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6)) {
            pickupsRingProgress = CGFloat(challenges[2].progress)
        }
    }

    // MARK: - Helpers

    private var streakTier: StreakTier { .from(days: streakDays) }

    private func challengeFor(_ ringType: RingType) -> Challenge? {
        dailyChallenges.first { $0.ringType == ringType }
    }

    private func ringProgress(for ringType: RingType) -> CGFloat {
        switch ringType {
        case .score: return scoreRingProgress
        case .screenTime: return screenTimeRingProgress
        case .pickups: return pickupsRingProgress
        }
    }

    private func formatDateISO(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Activity Rings Card

    private var activityRingsCard: some View {
        let challenges = dailyChallenges
        let allComplete = challenges.allSatisfy { $0.isComplete }

        return VStack(spacing: 16) {
            // Concentric rings
            ZStack {
                // Outer ring — Score (green)
                ringPair(
                    type: .score,
                    diameter: 160,
                    progress: scoreRingProgress,
                    isComplete: challenges[0].isComplete
                )

                // Middle ring — Screen Time (blue)
                ringPair(
                    type: .screenTime,
                    diameter: 116,
                    progress: screenTimeRingProgress,
                    isComplete: challenges[1].isComplete
                )

                // Inner ring — Pickups (purple)
                ringPair(
                    type: .pickups,
                    diameter: 72,
                    progress: pickupsRingProgress,
                    isComplete: challenges[2].isComplete
                )

                // Center: streak fire + count
                VStack(spacing: 0) {
                    Text(streakTier.fireEmoji)
                        .font(.system(size: 18))
                        .scaleEffect(fireScale)
                    Text("\(streakDays)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                }
            }
            .frame(height: 180)
            .padding(.top, 12)

            // Legend row
            HStack(spacing: 0) {
                ForEach(RingType.allCases, id: \.self) { ring in
                    legendItem(ring: ring)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedRing = (selectedRing == ring) ? nil : ring
                            }
                        }
                }
            }
            .padding(.horizontal, 4)

            // Expanded detail (if a ring is selected)
            if let ring = selectedRing, let challenge = challengeFor(ring) {
                VStack(spacing: 8) {
                    Divider().foregroundColor(BrainRotTheme.cardBorder)

                    HStack(spacing: 10) {
                        Text(challenge.emoji)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(challenge.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                            Text(challenge.description)
                                .font(.system(size: 12))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }

                        Spacer()

                        Text(challenge.isComplete ? "Done!" : "\(Int(challenge.progress * 100))%")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(challenge.isComplete ? BrainRotTheme.neonGreen : ring.color)
                    }

                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(ring.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .scaleEffect(x: max(0, min(1, challenge.progress)), y: 1, anchor: .leading)
                            .frame(height: 6)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .padding(.horizontal, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    allComplete
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [BrainRotTheme.neonGreen, BrainRotTheme.neonBlue, BrainRotTheme.neonPurple],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                          )
                        : AnyShapeStyle(BrainRotTheme.cardBorder),
                    lineWidth: allComplete ? 2 : 1
                )
        )
    }

    // MARK: - Ring Pair (track + fill)

    private func ringPair(type: RingType, diameter: CGFloat, progress: CGFloat, isComplete: Bool) -> some View {
        ZStack {
            // Background track
            Circle()
                .stroke(type.color.opacity(0.15), lineWidth: 14)
                .frame(width: diameter, height: diameter)

            // Filled arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    type.color,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))

            // Completion checkmark at end of ring
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(type.color)
                    .background(
                        Circle()
                            .fill(BrainRotTheme.cardBackground)
                            .frame(width: 18, height: 18)
                    )
                    .offset(y: -(diameter / 2))
            }
        }
        // Tap target
        .contentShape(Circle().size(width: diameter + 14, height: diameter + 14))
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedRing = (selectedRing == type) ? nil : type
            }
        }
    }

    // MARK: - Legend Item

    private func legendItem(ring: RingType) -> some View {
        let challenge = challengeFor(ring)
        let pct = Int((challenge?.progress ?? 0) * 100)
        let isSelected = selectedRing == ring
        let isComplete = challenge?.isComplete ?? false

        return VStack(spacing: 4) {
            // Color dot
            Circle()
                .fill(ring.color)
                .frame(width: 10, height: 10)

            // Label
            Text(ring.label)
                .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(isSelected ? ring.color : BrainRotTheme.textSecondary)

            // Percentage or checkmark
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(BrainRotTheme.neonGreen)
            } else {
                Text("\(pct)%")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(ring.color)
            }
        }
    }

    // MARK: - Streak Row

    private var streakRow: some View {
        HStack(spacing: 12) {
            // Fire + days
            HStack(spacing: 6) {
                Text(streakTier.fireEmoji)
                    .font(.system(size: 18))
                    .scaleEffect(fireScale)
                Text("\(streakDays)-day streak")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }

            Spacer()

            // Best streak
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 11))
                    .foregroundColor(BrainRotTheme.goldColor)
                Text("Best: \(bestStreak)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            // Tier badge
            HStack(spacing: 4) {
                Text(streakTier.icon).font(.system(size: 11))
                Text(streakTier.name)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(streakTier.color)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(streakTier.color.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(14)
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

    // MARK: - Daily Challenges Data

    private var dailyChallenges: [Challenge] {
        let limit = SharedSettings.dailyLimitMinutes
        let halfLimit = limit / 2.0
        var challenges: [Challenge] = []

        // 1. Score challenge (outer ring — green)
        if score > 50 {
            challenges.append(Challenge(
                emoji: "\u{1F3AF}", title: "Score Smasher",
                description: "Get your score below 50",
                progress: min(1.0, max(0, Double(100 - score) / 50.0)),
                isComplete: false,
                color: BrainRotTheme.neonGreen,
                ringType: .score
            ))
        } else {
            challenges.append(Challenge(
                emoji: "\u{1F3AF}", title: "Score Smasher",
                description: "Keep your score below 50",
                progress: 1.0, isComplete: true,
                color: BrainRotTheme.neonGreen,
                ringType: .score
            ))
        }

        // 2. Screen time challenge (middle ring — blue)
        let screenTimeGoal = halfLimit
        let stProgress = screenTimeMinutes > 0 ? min(1.0, (screenTimeGoal - screenTimeMinutes) / screenTimeGoal) : 1.0
        challenges.append(Challenge(
            emoji: "\u{23F1}\u{FE0F}", title: "Half Day Hero",
            description: "Stay under \(SharedSettings.formatLimit(screenTimeGoal))",
            progress: max(0, stProgress), isComplete: screenTimeMinutes <= screenTimeGoal,
            color: BrainRotTheme.neonBlue,
            ringType: .screenTime
        ))

        // 3. Pickups challenge (inner ring — purple)
        let pickupGoal = 30
        let pkProgress = pickups > 0 ? min(1.0, Double(pickupGoal - pickups) / Double(pickupGoal)) : 1.0
        challenges.append(Challenge(
            emoji: "\u{1F4F1}", title: "Phone Down",
            description: "Keep pickups under \(pickupGoal)",
            progress: max(0, pkProgress), isComplete: pickups <= pickupGoal,
            color: BrainRotTheme.neonPurple,
            ringType: .pickups
        ))

        return challenges
    }
}

// MARK: - Data Types

private enum RingType: String, CaseIterable {
    case score, screenTime, pickups

    var label: String {
        switch self {
        case .score: return "Score"
        case .screenTime: return "Time"
        case .pickups: return "Pickups"
        }
    }

    var color: Color {
        switch self {
        case .score: return BrainRotTheme.neonGreen
        case .screenTime: return BrainRotTheme.neonBlue
        case .pickups: return BrainRotTheme.neonPurple
        }
    }
}

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
    let color: Color
    let ringType: RingType
}
