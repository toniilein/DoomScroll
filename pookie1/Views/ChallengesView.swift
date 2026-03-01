import SwiftUI

struct ChallengesView: View {
    @State private var score = SharedSettings.lastScore
    @State private var pickups = SharedSettings.lastPickups
    @State private var screenTimeMinutes = SharedSettings.lastScreenTimeMinutes
    @State private var streakDays = SharedSettings.streakDays
    @State private var unlockedIDs = SharedSettings.unlockedAchievements

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Streak banner
                        streakBanner

                        // Daily challenges
                        dailyChallengesSection

                        // Weekly goals
                        weeklyGoalsSection

                        // Achievement gallery
                        achievementGallery
                    }
                    .padding()
                    .padding(.top, 4)
                }
            }
            .navigationTitle("Challenges")
            .onAppear { refreshData() }
        }
    }

    private func refreshData() {
        score = SharedSettings.lastScore
        pickups = SharedSettings.lastPickups
        screenTimeMinutes = SharedSettings.lastScreenTimeMinutes
        streakDays = SharedSettings.streakDays
        unlockedIDs = SharedSettings.unlockedAchievements
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("\(streakDays)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(streakDays > 0 ? BrainRotTheme.neonOrange : BrainRotTheme.textSecondary)
                Text("day streak")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(streakMessage)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                    .multilineTextAlignment(.trailing)

                Text("Score under 50 = streak day")
                    .font(.system(size: 11))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding(18)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(BrainRotTheme.neonOrange.opacity(streakDays > 0 ? 0.3 : 0.1), lineWidth: 1)
        )
    }

    private var streakMessage: String {
        switch streakDays {
        case 0: return "Start your streak today!"
        case 1: return "Day 1 - Let's go!"
        case 2...3: return "Building momentum!"
        case 4...6: return "You're on fire!"
        case 7...13: return "One week strong!"
        case 14...29: return "Unstoppable!"
        default: return "Legendary streak!"
        }
    }

    // MARK: - Daily Challenges

    private var dailyChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "flag.checkered", title: "Today's Challenges", color: BrainRotTheme.neonPink)

            VStack(spacing: 10) {
                ForEach(dailyChallenges) { challenge in
                    challengeCard(challenge)
                }
            }
        }
    }

    private var dailyChallenges: [Challenge] {
        let limit = SharedSettings.dailyLimitMinutes
        let halfLimit = limit / 2.0

        var challenges: [Challenge] = []

        // Score-based challenge
        if score > 50 {
            challenges.append(Challenge(
                emoji: "\u{1F3AF}",
                title: "Score Smasher",
                description: "Get your score below 50",
                progress: max(0, Double(100 - score) / 50.0),
                isComplete: score < 50
            ))
        } else {
            challenges.append(Challenge(
                emoji: "\u{1F3AF}",
                title: "Score Smasher",
                description: "Keep your score below 50",
                progress: 1.0,
                isComplete: true
            ))
        }

        // Screen time challenge
        let screenTimeGoal = halfLimit
        let stProgress = screenTimeMinutes > 0 ? min(1.0, (screenTimeGoal - screenTimeMinutes) / screenTimeGoal) : 1.0
        challenges.append(Challenge(
            emoji: "\u{23F1}\u{FE0F}",
            title: "Half Day Hero",
            description: "Stay under \(SharedSettings.formatLimit(screenTimeGoal))",
            progress: max(0, stProgress),
            isComplete: screenTimeMinutes <= screenTimeGoal
        ))

        // Pickup challenge
        let pickupGoal = 30
        let pkProgress = pickups > 0 ? min(1.0, Double(pickupGoal - pickups) / Double(pickupGoal)) : 1.0
        challenges.append(Challenge(
            emoji: "\u{1F4F1}",
            title: "Phone Down",
            description: "Keep pickups under \(pickupGoal)",
            progress: max(0, pkProgress),
            isComplete: pickups <= pickupGoal
        ))

        return challenges
    }

    private func challengeCard(_ challenge: Challenge) -> some View {
        HStack(spacing: 14) {
            Text(challenge.emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(challenge.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                    Spacer()
                    if challenge.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(BrainRotTheme.neonGreen)
                    }
                }

                Text(challenge.description)
                    .font(.system(size: 12))
                    .foregroundColor(BrainRotTheme.textSecondary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(challenge.isComplete ? BrainRotTheme.neonGreen : BrainRotTheme.neonPink)
                            .frame(width: geo.size.width * max(0, min(1, challenge.progress)), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(challenge.isComplete ? BrainRotTheme.neonGreen.opacity(0.3) : BrainRotTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Weekly Goals

    private var weeklyGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "calendar", title: "Weekly Goals", color: BrainRotTheme.neonBlue)

            VStack(spacing: 10) {
                weeklyGoalCard(
                    emoji: "\u{1F525}",
                    title: "7-Day Streak",
                    description: "Keep score under 50 for 7 consecutive days",
                    current: streakDays,
                    target: 7
                )

                weeklyGoalCard(
                    emoji: "\u{1F9D8}",
                    title: "Digital Detox",
                    description: "Score under 30 for 3 days this week",
                    current: min(3, streakDays),
                    target: 3
                )

                weeklyGoalCard(
                    emoji: "\u{1F4AA}",
                    title: "Consistency King",
                    description: "Open the app every day this week",
                    current: min(7, max(1, streakDays)),
                    target: 7
                )
            }
        }
    }

    private func weeklyGoalCard(emoji: String, title: String, description: String, current: Int, target: Int) -> some View {
        let progress = Double(min(current, target)) / Double(target)
        let isComplete = current >= target

        return HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                    Spacer()
                    Text("\(min(current, target))/\(target)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(isComplete ? BrainRotTheme.neonGreen : BrainRotTheme.neonBlue)
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(BrainRotTheme.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isComplete ? BrainRotTheme.neonGreen : BrainRotTheme.neonBlue)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isComplete ? BrainRotTheme.neonGreen.opacity(0.3) : BrainRotTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Achievement Gallery

    private var achievementGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "trophy.fill", title: "Achievements", color: BrainRotTheme.goldColor)

            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(allAchievements) { achievement in
                    achievementTile(achievement)
                }
            }
        }
    }

    private func achievementTile(_ achievement: AchievementInfo) -> some View {
        let isUnlocked = unlockedIDs.contains(achievement.id)

        return VStack(spacing: 6) {
            Text(achievement.emoji)
                .font(.system(size: 32))
                .opacity(isUnlocked ? 1.0 : 0.3)
                .grayscale(isUnlocked ? 0 : 1)

            Text(achievement.title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(isUnlocked ? BrainRotTheme.textPrimary : BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(achievement.requirement)
                .font(.system(size: 9))
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isUnlocked ? achievement.color.opacity(0.4) : BrainRotTheme.cardBorder,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Models

private struct Challenge: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    let progress: Double
    let isComplete: Bool
}

private struct AchievementInfo: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let requirement: String
    let color: Color
}

// All possible achievements (matches DoomAchievement in extension)
private let allAchievements: [AchievementInfo] = [
    AchievementInfo(id: "GRASS TOUCHER", emoji: "\u{1F33F}", title: "Grass Toucher", requirement: "Score under 20", color: BrainRotTheme.neonGreen),
    AchievementInfo(id: "ZEN MASTER", emoji: "\u{1F9D8}", title: "Zen Master", requirement: "Score of 0", color: BrainRotTheme.neonGreen),
    AchievementInfo(id: "PHONE ADDICT", emoji: "\u{1F4F1}", title: "Phone Addict", requirement: "50+ pickups", color: BrainRotTheme.neonPurple),
    AchievementInfo(id: "PICKUP ARTIST", emoji: "\u{1F3AF}", title: "Pickup Artist", requirement: "80+ pickups", color: BrainRotTheme.neonBlue),
    AchievementInfo(id: "MARATHON SCROLLER", emoji: "\u{23F1}\u{FE0F}", title: "Marathon Scroller", requirement: "3h on one app", color: BrainRotTheme.neonPink),
    AchievementInfo(id: "TERMINAL BRAINROT", emoji: "\u{1F9E0}\u{1F480}", title: "Terminal Brainrot", requirement: "Score over 90", color: BrainRotTheme.neonPink),
]
