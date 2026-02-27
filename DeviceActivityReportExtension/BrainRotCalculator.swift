import Foundation

enum BrainRotCalculator {
    /// Shared App Group UserDefaults for reading daily limit
    private static let sharedSuiteName = "group.pookie1.shared"
    private static let dailyLimitKey = "dailyLimitMinutes"
    private static let defaultDailyLimit: Double = 240

    private static var dailyLimitMinutes: Double {
        let defaults = UserDefaults(suiteName: sharedSuiteName)
        let val = defaults?.double(forKey: dailyLimitKey) ?? 0
        return val > 0 ? val : defaultDailyLimit
    }

    static func score(totalMinutes: Double) -> Int {
        let limit = dailyLimitMinutes
        guard totalMinutes > 0 else { return 0 }

        // Ratio of actual usage to personal daily limit
        let ratio = totalMinutes / limit

        let score: Double
        if ratio <= 0.5 {
            // 0-50% of limit: score 0-30 (healthy)
            score = ratio * 2.0 * 30.0
        } else if ratio <= 1.0 {
            // 50-100% of limit: score 30-65
            score = 30.0 + (ratio - 0.5) * 2.0 * 35.0
        } else if ratio <= 1.5 {
            // 100-150% of limit: score 65-85
            score = 65.0 + (ratio - 1.0) * 2.0 * 20.0
        } else if ratio <= 2.0 {
            // 150-200% of limit: score 85-95
            score = 85.0 + (ratio - 1.5) * 2.0 * 10.0
        } else {
            // 200%+ of limit: score 95-99 (asymptotic)
            score = 95.0 + min(4.0, (ratio - 2.0) * 2.0)
        }

        return Int(min(99, max(0, score)))
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - Smart KPI Calculations

    static func computeSmartKPIs(
        totalDuration: TimeInterval,
        totalPickups: Int,
        topApps: [AppUsageData],
        brainRotScore: Int
    ) -> SmartKPIs {
        let totalMinutes = totalDuration / 60.0

        // Avg session length
        let avgSessionMin = totalPickups > 0 ? totalMinutes / Double(totalPickups) : 0

        // Pickup frequency (how often you grab your phone, in waking minutes = 960)
        let pickupFreqMin = totalPickups > 0 ? 960.0 / Double(totalPickups) : 960

        // Doom ratio: top app's % of total
        let topApp = topApps.first
        let doomRatio = (totalDuration > 0 && topApp != nil) ? (topApp!.duration / totalDuration) * 100 : 0
        let doomAppName = topApp?.displayName ?? "None"

        // Pickups per hour (16 waking hours)
        let pickupsPerHour = Double(totalPickups) / 16.0

        // Addiction index: combines frequency + depth
        let addictionIndex = pickupsPerHour * avgSessionMin / 2.0

        // Focus destroyer: app with most pickups
        let focusDestroyer = topApps.max(by: { $0.numberOfPickups < $1.numberOfPickups })
        let focusDestroyerName = focusDestroyer?.displayName ?? "None"
        let focusDestroyerPickups = focusDestroyer?.numberOfPickups ?? 0

        // Brain remaining
        let brainRemaining = 100 - brainRotScore

        // Scroll type
        let scrollType = classifyScrollType(
            avgSessionMin: avgSessionMin,
            totalPickups: totalPickups,
            totalMinutes: totalMinutes
        )

        // Achievements
        let achievements = computeAchievements(
            brainRotScore: brainRotScore,
            totalPickups: totalPickups,
            topApps: topApps,
            avgSessionMin: avgSessionMin
        )

        return SmartKPIs(
            avgSessionMinutes: avgSessionMin,
            pickupFrequencyMinutes: pickupFreqMin,
            doomRatioPercent: doomRatio,
            doomRatioAppName: doomAppName,
            addictionIndex: addictionIndex,
            pickupsPerHour: pickupsPerHour,
            focusDestroyerApp: focusDestroyerName,
            focusDestroyerPickups: focusDestroyerPickups,
            brainRemaining: brainRemaining,
            scrollType: scrollType,
            achievements: achievements
        )
    }

    static func classifyScrollType(
        avgSessionMin: Double,
        totalPickups: Int,
        totalMinutes: Double
    ) -> ScrollType {
        if totalMinutes < 30 && totalPickups < 10 {
            return .digitalMonk
        }
        if avgSessionMin > 15 && totalPickups < 20 {
            return .bingeWatcher
        }
        if totalPickups > 30 && avgSessionMin < 8 {
            return .compulsiveChecker
        }
        return .balancedDoom
    }

    static func computeAchievements(
        brainRotScore: Int,
        totalPickups: Int,
        topApps: [AppUsageData],
        avgSessionMin: Double
    ) -> [DoomAchievement] {
        var achievements: [DoomAchievement] = []

        if brainRotScore < 20 {
            achievements.append(.grassToucher)
        }
        if brainRotScore > 90 {
            achievements.append(.terminalBrainrot)
        }
        if totalPickups > 50 {
            achievements.append(.phoneAddict)
        }
        if let topApp = topApps.first, topApp.duration > 10800 {
            achievements.append(.marathonScroller)
        }
        if brainRotScore == 0 {
            achievements.append(.zenMaster)
        }
        if totalPickups > 80 {
            achievements.append(.pickupArtist)
        }

        return achievements
    }

    // MARK: - Snarky Text Generators

    static func snarkyOneLiner(for score: Int) -> String {
        switch score {
        case 0:
            return "Did you even use your phone today?"
        case 1..<15:
            return "Touching grass professionally"
        case 15..<30:
            return "Your brain cells are thriving"
        case 30..<45:
            return "The algorithm is warming up on you"
        case 45..<60:
            return "You're feeding the algorithm well"
        case 60..<75:
            return "Your brain is entering the void"
        case 75..<90:
            return "The phone has become your personality"
        case 90..<100:
            return "Your brain has left the chat"
        default:
            return "Peak brainrot achieved. Congrats?"
        }
    }

    static func avgSessionText(minutes: Double) -> String {
        if minutes < 2 {
            return "Quick peeks"
        } else if minutes < 5 {
            return "\(Int(minutes))m per peek"
        } else if minutes < 15 {
            return "\(Int(minutes))m per session"
        } else if minutes < 30 {
            return "\(Int(minutes))m locked in"
        } else {
            return "\(Int(minutes))m per binge"
        }
    }

    static func pickupFrequencyText(minutes: Double) -> String {
        if minutes > 120 {
            return "Phone? What phone?"
        } else if minutes > 60 {
            return "Every \(Int(minutes))m"
        } else if minutes > 15 {
            return "Every \(Int(minutes))m"
        } else {
            return "Every \(Int(minutes))m yikes"
        }
    }

    static func addictionIndexLabel(_ index: Double) -> String {
        switch index {
        case ..<5: return "Healthy"
        case 5..<15: return "Moderate"
        case 15..<30: return "High"
        case 30..<50: return "Extreme"
        default: return "Off the charts"
        }
    }

    static func dailyChallenge(for score: Int, pickups: Int) -> String {
        if score > 80 {
            return "CHALLENGE: Get your score under 50 today"
        } else if score > 50 {
            return "CHALLENGE: Close your top app for 2 hours"
        } else if pickups > 40 {
            return "CHALLENGE: Keep pickups under 20 today"
        } else if score > 30 {
            return "CHALLENGE: No scrolling for the next hour"
        } else {
            return "CHALLENGE: Keep this streak going!"
        }
    }
}
