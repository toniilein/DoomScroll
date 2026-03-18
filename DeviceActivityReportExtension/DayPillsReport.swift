import DeviceActivity
import ManagedSettings
import SwiftUI

struct DayPillData: Identifiable {
    let id: Int // offset from today (0 = today, -1 = yesterday, etc.)
    let date: Date
    let dayLabel: String // "Mon", "Tue", etc.
    let dayNumber: String // "1", "2", etc.
    let score: Int
    let formattedDuration: String // "2h 15m", "45m", etc.
    let isToday: Bool
    let hasData: Bool
}

struct DayPillsData {
    let days: [DayPillData]
}

struct DayPillsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .dayPills
    let content: (DayPillsData) -> DayPillsView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> DayPillsData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Collect duration per day from the data
        var dayDurations: [Date: TimeInterval] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                let segmentDate = calendar.startOfDay(for: segment.dateInterval.start)
                let existing = dayDurations[segmentDate] ?? 0
                dayDurations[segmentDate] = existing + segment.totalActivityDuration
            }
        }

        // Read which days to show from shared UserDefaults
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let weekOffset = shared?.integer(forKey: "dayPillsWeekOffset") ?? 0

        // Also save scores for each day while we have the data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for (date, duration) in dayDurations where duration > 0 {
            let dayKey = "score_" + dateFormatter.string(from: date)
            let dayScore = BrainRotCalculator.score(totalMinutes: duration / 60.0)
            shared?.set(dayScore, forKey: dayKey)
        }
        shared?.synchronize()

        // Build day pills for the requested week
        let dayLabelFormatter = DateFormatter()
        dayLabelFormatter.dateFormat = "EEE"
        let dayNumberFormatter = DateFormatter()
        dayNumberFormatter.dateFormat = "d"

        let weekStart = weekOffset * 7
        var days: [DayPillData] = []

        for i in 0..<7 {
            let dayOffset = weekStart - (6 - i)
            // Don't show future days
            if dayOffset > 0 { continue }

            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let startOfDate = calendar.startOfDay(for: date)
            let duration = dayDurations[startOfDate] ?? 0
            let score = duration > 0
                ? BrainRotCalculator.score(totalMinutes: duration / 60.0)
                : 0
            let hasData = duration > 0

            let label = String(dayLabelFormatter.string(from: date).prefix(3))
            let number = dayNumberFormatter.string(from: date)

            let formatted = DayPillsReport.formatDuration(duration)

            days.append(DayPillData(
                id: dayOffset,
                date: date,
                dayLabel: label,
                dayNumber: number,
                score: score,
                formattedDuration: formatted,
                isToday: dayOffset == 0,
                hasData: hasData
            ))
        }

        return DayPillsData(days: days)
    }

    private static func formatDuration(_ seconds: TimeInterval) -> String {
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
}
