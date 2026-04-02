import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

struct DayBreakdown: Identifiable {
    let id: Int
    let date: Date
    let dateKey: String
    let dayLabel: String
    let dayNumber: String
    let score: Int
    let duration: TimeInterval
    let formattedDuration: String
    let pickups: Int
    let apps: [AppUsageData]
    let categories: [CategoryUsageData]
    let isToday: Bool
    let hasData: Bool
}

struct TotalActivityData {
    let days: [DayBreakdown]       // 7 days of data
    let selectedDayIndex: Int      // which day to show initially
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (TotalActivityData) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> TotalActivityData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Collect per-day data from segments
        var dayDurations: [Date: TimeInterval] = [:]
        var dayPickups: [Date: Int] = [:]
        var dayApps: [Date: [AppUsageData]] = [:]
        // category name -> (duration, pickups, [apps])
        var dayCategoryData: [Date: [String: (duration: TimeInterval, pickups: Int, apps: [AppUsageData])]] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                let segDate = calendar.startOfDay(for: segment.dateInterval.start)
                dayDurations[segDate, default: 0] += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? "Other"

                    for await appActivity in categoryActivity.applications {
                        let appName = appActivity.application.localizedDisplayName ?? "Unknown"
                        let appDuration = appActivity.totalActivityDuration
                        let pickups = appActivity.numberOfPickups
                        dayPickups[segDate, default: 0] += pickups

                        if appDuration > 0 {
                            let appData = AppUsageData(
                                displayName: appName,
                                duration: appDuration,
                                formattedDuration: BrainRotCalculator.formatDuration(appDuration),
                                numberOfPickups: pickups
                            )

                            var apps = dayApps[segDate] ?? []
                            apps.append(appData)
                            dayApps[segDate] = apps

                            var catMap = dayCategoryData[segDate] ?? [:]
                            var existing = catMap[catName] ?? (duration: 0, pickups: 0, apps: [])
                            existing.duration += appDuration
                            existing.pickups += pickups
                            existing.apps.append(appData)
                            catMap[catName] = existing
                            dayCategoryData[segDate] = catMap
                        }
                    }
                }
            }
        }

        // Read which day is selected
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let selectedOffset = shared?.integer(forKey: "selectedDayOffset") ?? 0

        // Build 7 day breakdowns
        let dayLabelFmt = DateFormatter()
        dayLabelFmt.dateFormat = "EEE"
        let dayNumFmt = DateFormatter()
        dayNumFmt.dateFormat = "d"
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        var days: [DayBreakdown] = []
        var selectedIndex = 6 // default to last (today)

        for i in 0..<7 {
            let offset = i - 6 // -6, -5, -4, -3, -2, -1, 0
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            let duration = dayDurations[date] ?? 0
            let pickups = dayPickups[date] ?? 0
            var apps = dayApps[date] ?? []
            apps.sort { $0.duration > $1.duration }
            let score = duration > 0 ? BrainRotCalculator.score(totalMinutes: duration / 60.0) : 0
            let hasData = duration > 0

            // Build categories for this day
            let catMap = dayCategoryData[date] ?? [:]
            var categories: [CategoryUsageData] = catMap.map { name, data in
                var sortedApps = data.apps
                sortedApps.sort { $0.duration > $1.duration }
                return CategoryUsageData(
                    categoryName: name,
                    duration: data.duration,
                    formattedDuration: BrainRotCalculator.formatDuration(data.duration),
                    pickups: data.pickups,
                    apps: sortedApps
                )
            }
            categories.sort { $0.duration > $1.duration }

            if offset == selectedOffset {
                selectedIndex = i
            }

            days.append(DayBreakdown(
                id: offset,
                date: date,
                dateKey: dateFmt.string(from: date),
                dayLabel: String(dayLabelFmt.string(from: date).prefix(3)),
                dayNumber: dayNumFmt.string(from: date),
                score: score,
                duration: duration,
                formattedDuration: BrainRotCalculator.formatDuration(duration),
                pickups: pickups,
                apps: apps,
                categories: categories,
                isToday: offset == 0,
                hasData: hasData
            ))
        }

        // Save today's data to shared for other features (share card, challenges, shield)
        if let todayData = days.last, todayData.hasData {
            shared?.set(todayData.score, forKey: "lastBrainRotScore")
            shared?.set(todayData.duration / 60.0, forKey: "lastScreenTimeMinutes")
            shared?.set(todayData.pickups, forKey: "lastPickups")

            // Save per-category durations as individual simple keys
            var categoryNames: [String] = []
            for cat in todayData.categories {
                shared?.set(cat.duration / 60.0, forKey: "catMin_\(cat.categoryName)")
                categoryNames.append(cat.categoryName)
            }
            shared?.set(categoryNames, forKey: "todayCategoryNames")
            // Also write as a simple string for reliable cross-process read
            shared?.set(categoryNames.joined(separator: "|||"), forKey: "todayCategoryNamesStr")

            // Save per-app durations as individual simple keys
            var appNames: [String] = []
            for app in todayData.apps {
                shared?.set(app.duration / 60.0, forKey: "appMin_\(app.displayName)")
                appNames.append(app.displayName)
            }
            shared?.set(appNames, forKey: "todayAppNames")
        }
        shared?.synchronize()

        return TotalActivityData(
            days: days,
            selectedDayIndex: selectedIndex
        )
    }

}
