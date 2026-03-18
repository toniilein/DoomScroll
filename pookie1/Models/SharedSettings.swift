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

    // MARK: - Per-Day Data (written by extension reports)
    // Use a fresh UserDefaults instance each time to avoid cross-process caching issues

    static func scoreForDay(_ dateKey: String) -> Int? {
        guard let fresh = UserDefaults(suiteName: suiteName) else { return nil }
        let key = "score_" + dateKey
        if fresh.object(forKey: key) != nil {
            return fresh.integer(forKey: key)
        }
        return nil
    }

    static func durationForDay(_ dateKey: String) -> TimeInterval? {
        guard let fresh = UserDefaults(suiteName: suiteName) else { return nil }
        let key = "duration_" + dateKey
        let val = fresh.double(forKey: key)
        return val > 0 ? val : nil
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h\(mins > 0 ? " \(mins)m" : "")"
        } else if mins > 0 {
            return "\(mins)m"
        }
        return "0m"
    }

    // MARK: - Block Routines

    static let blockRoutinesKey = "blockRoutines"

    static var blockRoutines: [BlockRoutine] {
        get {
            guard let data = sharedDefaults.data(forKey: blockRoutinesKey),
                  let routines = try? JSONDecoder().decode([BlockRoutine].self, from: data) else {
                return []
            }
            return routines
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                sharedDefaults.set(data, forKey: blockRoutinesKey)
            }
        }
    }

    static func saveRoutine(_ routine: BlockRoutine) {
        var routines = blockRoutines
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
        } else {
            routines.append(routine)
        }
        blockRoutines = routines
    }

    static func deleteRoutine(id: UUID) {
        var routines = blockRoutines
        routines.removeAll { $0.id == id }
        blockRoutines = routines
    }

    // MARK: - Usage Limits

    static let usageLimitsKey = "usageLimits"

    static var usageLimits: [UsageLimit] {
        get {
            guard let data = sharedDefaults.data(forKey: usageLimitsKey),
                  let limits = try? JSONDecoder().decode([UsageLimit].self, from: data) else {
                return []
            }
            return limits
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                sharedDefaults.set(data, forKey: usageLimitsKey)
            }
        }
    }

    static func saveUsageLimit(_ limit: UsageLimit) {
        var limits = usageLimits
        if let index = limits.firstIndex(where: { $0.id == limit.id }) {
            limits[index] = limit
        } else {
            limits.append(limit)
        }
        usageLimits = limits
    }

    static func deleteUsageLimit(id: UUID) {
        var limits = usageLimits
        limits.removeAll { $0.id == id }
        usageLimits = limits
    }

    // MARK: - Per-category/app usage (written by extension as individual keys)

    static var todayCategoryMinutes: [String: Double] {
        let names = sharedDefaults.stringArray(forKey: "todayCategoryNames") ?? []
        var result: [String: Double] = [:]
        for name in names {
            let mins = sharedDefaults.double(forKey: "catMin_\(name)")
            if mins > 0 { result[name] = mins }
        }
        return result
    }

    static var todayAppMinutes: [String: Double] {
        let names = sharedDefaults.stringArray(forKey: "todayAppNames") ?? []
        var result: [String: Double] = [:]
        for name in names {
            let mins = sharedDefaults.double(forKey: "appMin_\(name)")
            if mins > 0 { result[name] = mins }
        }
        return result
    }

    static func categoryMinutes(for categoryName: String) -> Double {
        sharedDefaults.double(forKey: "catMin_\(categoryName)")
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
