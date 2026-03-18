import Foundation

enum SharedSettings {
    static let suiteName = "group.pookie1.shared"
    static let dailyLimitKey = "dailyLimitMinutes"
    static let defaultDailyLimit: Double = 240 // 4 hours

    // Keys for challenge data (written by extension, read by host)
    static let lastScoreKey = "lastBrainRotScore"
    static let lastPickupsKey = "lastPickups"
    static let lastScreenTimeKey = "lastScreenTimeMinutes"
    static let streakDaysKey = "streakDays"
    static let unlockedAchievementsKey = "unlockedAchievements"
    static let lastUpdatedKey = "lastChallengeDataUpdate"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static var dailyLimitMinutes: Double {
        get {
            let val = sharedDefaults.double(forKey: dailyLimitKey)
            return val > 0 ? val : defaultDailyLimit
        }
        set {
            sharedDefaults.set(newValue, forKey: dailyLimitKey)
        }
    }

    // MARK: - Challenge Data (read by host)

    static var lastScore: Int {
        get { sharedDefaults.integer(forKey: lastScoreKey) }
        set { sharedDefaults.set(newValue, forKey: lastScoreKey) }
    }

    static var lastPickups: Int {
        get { sharedDefaults.integer(forKey: lastPickupsKey) }
        set { sharedDefaults.set(newValue, forKey: lastPickupsKey) }
    }

    static var lastScreenTimeMinutes: Double {
        get { sharedDefaults.double(forKey: lastScreenTimeKey) }
        set { sharedDefaults.set(newValue, forKey: lastScreenTimeKey) }
    }

    static var streakDays: Int {
        get { sharedDefaults.integer(forKey: streakDaysKey) }
        set { sharedDefaults.set(newValue, forKey: streakDaysKey) }
    }

    static var unlockedAchievements: [String] {
        get { sharedDefaults.stringArray(forKey: unlockedAchievementsKey) ?? [] }
        set { sharedDefaults.set(newValue, forKey: unlockedAchievementsKey) }
    }

    static var lastUpdated: Date? {
        get { sharedDefaults.object(forKey: lastUpdatedKey) as? Date }
        set { sharedDefaults.set(newValue, forKey: lastUpdatedKey) }
    }

    // MARK: - Streak Extras

    static let bestStreakKey = "bestStreakDays"
    static let streakHistoryKey = "streakHistory" // dates of streak days as ISO strings
    static let streakFreezeCountKey = "streakFreezeCount"

    static var bestStreak: Int {
        get {
            let val = sharedDefaults.integer(forKey: bestStreakKey)
            return max(val, streakDays) // always at least current
        }
        set { sharedDefaults.set(newValue, forKey: bestStreakKey) }
    }

    static var streakHistory: [String] {
        get { sharedDefaults.stringArray(forKey: streakHistoryKey) ?? [] }
        set { sharedDefaults.set(newValue, forKey: streakHistoryKey) }
    }

    static var streakFreezeCount: Int {
        get { sharedDefaults.integer(forKey: streakFreezeCountKey) }
        set { sharedDefaults.set(newValue, forKey: streakFreezeCountKey) }
    }

    /// Records today as a streak day if not already recorded
    static func recordStreakDay() {
        let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: .now)).prefix(10)
        var history = streakHistory
        let todayStr = String(today)
        if !history.contains(todayStr) {
            history.append(todayStr)
            // Keep last 90 days max
            if history.count > 90 {
                history = Array(history.suffix(90))
            }
            streakHistory = history
        }
        if streakDays > bestStreak {
            bestStreak = streakDays
        }
    }

    // MARK: - Quest History (per-day quest completion)

    static let questHistoryKey = "questHistory"

    /// Dictionary of date string -> [Bool] (quest1 complete, quest2 complete, quest3 complete)
    static var questHistory: [String: [Bool]] {
        get {
            guard let data = sharedDefaults.data(forKey: questHistoryKey),
                  let dict = try? JSONDecoder().decode([String: [Bool]].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                sharedDefaults.set(data, forKey: questHistoryKey)
            }
        }
    }

    /// Save today's quest results
    static func recordQuestResults(_ results: [Bool]) {
        let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: .now)).prefix(10)
        var history = questHistory
        history[String(today)] = results
        // Keep last 90 days
        if history.count > 90 {
            let sorted = history.keys.sorted()
            for key in sorted.prefix(history.count - 90) {
                history.removeValue(forKey: key)
            }
        }
        questHistory = history
    }

    // MARK: - Achievement History (per-day)

    static let achievementHistoryKey = "achievementHistory"

    /// Dictionary of date string -> [String] (achievement IDs earned that day)
    static var achievementHistory: [String: [String]] {
        get {
            guard let data = sharedDefaults.data(forKey: achievementHistoryKey),
                  let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                sharedDefaults.set(data, forKey: achievementHistoryKey)
            }
        }
    }

    /// Save today's achievements
    static func recordAchievements(_ achievementIDs: [String]) {
        let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: .now)).prefix(10)
        var history = achievementHistory
        history[String(today)] = achievementIDs
        if history.count > 90 {
            let sorted = history.keys.sorted()
            for key in sorted.prefix(history.count - 90) {
                history.removeValue(forKey: key)
            }
        }
        achievementHistory = history
    }

    // MARK: - Daily Score History (per-day score for mini octopus)

    /// Get score for a specific date key (format: "yyyy-MM-dd")
    static func scoreForDay(_ dateKey: String) -> Int? {
        // Force re-read from disk (extension writes cross-process)
        sharedDefaults.synchronize()
        let key = "score_" + dateKey
        if sharedDefaults.object(forKey: key) != nil {
            return sharedDefaults.integer(forKey: key)
        }
        return nil
    }

    /// Save score for today
    static func recordDailyScore(_ score: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Calendar.current.startOfDay(for: .now))
        sharedDefaults.set(score, forKey: "score_" + today)
    }

    static func formatLimit(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}
