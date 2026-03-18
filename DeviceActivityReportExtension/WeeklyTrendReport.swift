import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

struct WeeklyTrendReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .weeklyTrend
    let content: (WeeklyTrendData) -> WeeklyTrendView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> WeeklyTrendData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Build a dictionary of date -> duration
        var dayDurations: [Date: TimeInterval] = [:]

        // Pre-fill last 7 days with 0
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: today) {
                dayDurations[calendar.startOfDay(for: date)] = 0
            }
        }

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                let segmentDate = calendar.startOfDay(for: segment.dateInterval.start)
                let existing = dayDurations[segmentDate] ?? 0
                dayDurations[segmentDate] = existing + segment.totalActivityDuration
            }
        }

        // Save per-day scores for mini octopus day selector
        // This saves scores for ALL segments the extension received (any date range)
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for (date, duration) in dayDurations where duration > 0 {
            let dayKey = "score_" + dateFormatter.string(from: date)
            let dayScore = BrainRotCalculator.score(totalMinutes: duration / 60.0)
            shared?.set(dayScore, forKey: dayKey)
        }
        shared?.synchronize()

        // Build daily scores sorted by date
        var dailyScores: [DailyScore] = []
        var weeklyTotal: TimeInterval = 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: today) {
                let startOfDate = calendar.startOfDay(for: date)
                let duration = dayDurations[startOfDate] ?? 0
                weeklyTotal += duration
                let totalMinutes = duration / 60.0
                let score = BrainRotCalculator.score(totalMinutes: totalMinutes)
                let weekday = calendar.component(.weekday, from: date)
                let labelIndex = weekday == 1 ? 6 : weekday - 2
                let label = dayLabels[labelIndex]

                dailyScores.append(DailyScore(
                    dayLabel: label,
                    score: score,
                    duration: duration,
                    formattedDuration: BrainRotCalculator.formatDuration(duration),
                    isToday: calendar.isDateInToday(date)
                ))
            }
        }

        // Calculate average
        let totalScore = dailyScores.reduce(0) { $0 + $1.score }
        let avgScore = dailyScores.isEmpty ? 0 : totalScore / dailyScores.count

        // Determine trend
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

        // Streak: consecutive days (from today backwards) with score < 50
        var streakDays = 0
        for day in dailyScores.reversed() {
            if day.score < 50 {
                streakDays += 1
            } else {
                break
            }
        }

        // Best and worst day indices
        var bestIdx: Int? = nil
        var worstIdx: Int? = nil
        if !dailyScores.isEmpty {
            var bestScore = Int.max
            var worstScore = Int.min
            for (i, day) in dailyScores.enumerated() {
                // Best = lowest score (least brainrot)
                if day.score < bestScore {
                    bestScore = day.score
                    bestIdx = i
                }
                // Worst = highest score (most brainrot)
                if day.score > worstScore {
                    worstScore = day.score
                    worstIdx = i
                }
            }
        }

        return WeeklyTrendData(
            dailyScores: dailyScores,
            averageScore: avgScore,
            trend: trend,
            streakDays: streakDays,
            weeklyTotal: weeklyTotal,
            formattedWeeklyTotal: BrainRotCalculator.formatDuration(weeklyTotal),
            bestDayIndex: bestIdx,
            worstDayIndex: worstIdx
        )
    }
}
