import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

struct BrainHealthData {
    let totalDuration: TimeInterval
    let brainRotScore: Int
    let formattedDuration: String
    let totalPickups: Int
    let longestSessionMinutes: Int
    let topApps: [AppUsageData]
    let allApps: [AppUsageData]
    let smartKPIs: SmartKPIs
    let weeklyTrend: WeeklyTrendData
}

struct BrainHealthReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .brainHealth
    let content: (BrainHealthData) -> BrainHealthReportView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> BrainHealthData {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)

        // --- Collect all segments, grouped by day ---
        var todayDuration: TimeInterval = 0
        var todayPickups = 0
        var todayLongestSession: TimeInterval = 0
        var todayAppUsages: [AppUsageData] = []

        // For weekly trend
        var dayDurations: [Date: TimeInterval] = [:]
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        // Pre-fill last 7 days with 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: todayStart) {
                dayDurations[calendar.startOfDay(for: date)] = 0
            }
        }

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                let segmentDate = calendar.startOfDay(for: segment.dateInterval.start)
                let segmentDuration = segment.totalActivityDuration

                // Weekly trend accumulation
                let existing = dayDurations[segmentDate] ?? 0
                dayDurations[segmentDate] = existing + segmentDuration

                // Today-only: drill into apps for brain health KPIs
                let isToday = calendar.isDate(segmentDate, inSameDayAs: todayStart)
                if isToday {
                    todayDuration += segmentDuration

                    for await categoryActivity in segment.categories {
                        for await appActivity in categoryActivity.applications {
                            let appName = appActivity.application.localizedDisplayName ?? "Unknown App"
                            let appDuration = appActivity.totalActivityDuration
                            let pickups = appActivity.numberOfPickups
                            todayPickups += pickups

                            if appDuration > todayLongestSession {
                                todayLongestSession = appDuration
                            }

                            if appDuration > 0 {
                                todayAppUsages.append(AppUsageData(
                                    displayName: appName,
                                    duration: appDuration,
                                    formattedDuration: BrainRotCalculator.formatDuration(appDuration),
                                    numberOfPickups: pickups
                                ))
                            }
                        }
                    }
                }
            }
        }

        // --- Today's brain health stats ---
        todayAppUsages.sort { $0.duration > $1.duration }
        let topApps = Array(todayAppUsages.prefix(10))

        let totalMinutes = todayDuration / 60.0
        let score = BrainRotCalculator.score(totalMinutes: totalMinutes)
        let formatted = BrainRotCalculator.formatDuration(todayDuration)
        let longestMins = Int(todayLongestSession / 60.0)

        let smartKPIs = BrainRotCalculator.computeSmartKPIs(
            totalDuration: todayDuration,
            totalPickups: todayPickups,
            topApps: topApps,
            brainRotScore: score
        )

        // --- Weekly trend ---
        var dailyScores: [DailyScore] = []
        var weeklyTotal: TimeInterval = 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: todayStart) {
                let startOfDate = calendar.startOfDay(for: date)
                let duration = dayDurations[startOfDate] ?? 0
                weeklyTotal += duration
                let dayMinutes = duration / 60.0
                let dayScore = BrainRotCalculator.score(totalMinutes: dayMinutes)
                let weekday = calendar.component(.weekday, from: date)
                let labelIndex = weekday == 1 ? 6 : weekday - 2
                let label = dayLabels[labelIndex]

                dailyScores.append(DailyScore(
                    dayLabel: label,
                    score: dayScore,
                    duration: duration,
                    formattedDuration: BrainRotCalculator.formatDuration(duration),
                    isToday: calendar.isDateInToday(date)
                ))
            }
        }

        let totalScoreSum = dailyScores.reduce(0) { $0 + $1.score }
        let avgScore = dailyScores.isEmpty ? 0 : totalScoreSum / dailyScores.count

        let firstHalf = dailyScores.prefix(3).map(\.score)
        let secondHalf = dailyScores.suffix(3).map(\.score)
        let firstAvg = firstHalf.isEmpty ? 0 : firstHalf.reduce(0, +) / firstHalf.count
        let secondAvg = secondHalf.isEmpty ? 0 : secondHalf.reduce(0, +) / secondHalf.count

        let trend: TrendDirection
        if secondAvg < firstAvg - 5 {
            trend = .improving
        } else if secondAvg > firstAvg + 5 {
            trend = .worsening
        } else {
            trend = .stable
        }

        var streakDays = 0
        for day in dailyScores.reversed() {
            if day.score < 50 { streakDays += 1 } else { break }
        }

        var bestIdx: Int? = nil
        var worstIdx: Int? = nil
        if !dailyScores.isEmpty {
            var bestScore = Int.max
            var worstScore = Int.min
            for (i, day) in dailyScores.enumerated() {
                if day.score < bestScore { bestScore = day.score; bestIdx = i }
                if day.score > worstScore { worstScore = day.score; worstIdx = i }
            }
        }

        let weeklyTrend = WeeklyTrendData(
            dailyScores: dailyScores,
            averageScore: avgScore,
            trend: trend,
            streakDays: streakDays,
            weeklyTotal: weeklyTotal,
            formattedWeeklyTotal: BrainRotCalculator.formatDuration(weeklyTotal),
            bestDayIndex: bestIdx,
            worstDayIndex: worstIdx
        )

        // Write challenge data to shared UserDefaults so the host Challenges tab can read it
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        shared?.set(score, forKey: "lastBrainRotScore")
        shared?.set(todayPickups, forKey: "lastPickups")
        shared?.set(totalMinutes, forKey: "lastScreenTimeMinutes")
        shared?.set(streakDays, forKey: "streakDays")
        shared?.set(Date(), forKey: "lastChallengeDataUpdate")

        // Write unlocked achievement IDs
        let achievementIDs = smartKPIs.achievements.map { $0.id }
        shared?.set(achievementIDs, forKey: "unlockedAchievements")

        return BrainHealthData(
            totalDuration: todayDuration,
            brainRotScore: score,
            formattedDuration: formatted,
            totalPickups: todayPickups,
            longestSessionMinutes: longestMins,
            topApps: topApps,
            allApps: todayAppUsages,
            smartKPIs: smartKPIs,
            weeklyTrend: weeklyTrend
        )
    }
}
