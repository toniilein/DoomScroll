import DeviceActivity
import ExtensionKit
import FamilyControls
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

        // For per-limit usage: track today's app token durations and category mappings
        var todayAppTokenDurations: [ApplicationToken: TimeInterval] = [:]
        var todayAppToCatTokens: [ApplicationToken: Set<ActivityCategoryToken>] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                let segDate = calendar.startOfDay(for: segment.dateInterval.start)
                dayDurations[segDate, default: 0] += segment.totalActivityDuration
                let isToday = segDate == today

                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? "Other"
                    let catToken = categoryActivity.category.token

                    for await appActivity in categoryActivity.applications {
                        let appName = appActivity.application.localizedDisplayName ?? "Unknown"
                        let appDuration = appActivity.totalActivityDuration
                        let pickups = appActivity.numberOfPickups
                        dayPickups[segDate, default: 0] += pickups

                        // Track token durations for today's limit usage
                        if isToday, appDuration > 0, let appToken = appActivity.application.token {
                            todayAppTokenDurations[appToken, default: 0] += appDuration
                            if let catToken {
                                todayAppToCatTokens[appToken, default: []].insert(catToken)
                            }
                        }

                        if appDuration > 0 {
                            let appData = AppUsageData(
                                displayName: appName,
                                duration: appDuration,
                                formattedDuration: BrainRotCalculator.formatDuration(appDuration),
                                numberOfPickups: pickups,
                                categoryName: catName
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

        // Compute and save per-limit usage from token data
        Self.computeLimitUsage(
            appTokenDurations: todayAppTokenDurations,
            appToCatTokens: todayAppToCatTokens,
            defaults: shared
        )

        shared?.synchronize()

        return TotalActivityData(
            days: days,
            selectedDayIndex: selectedIndex
        )
    }

    // MARK: - Per-Limit Usage

    private struct LimitConfig: Codable {
        let id: UUID
        let name: String
        let appSelectionData: Data?
        let limitMinutes: Int
        let isEnabled: Bool
        let activeDays: Set<Int>?
    }

    private static func computeLimitUsage(
        appTokenDurations: [ApplicationToken: TimeInterval],
        appToCatTokens: [ApplicationToken: Set<ActivityCategoryToken>],
        defaults: UserDefaults?
    ) {
        // Read limit configs from shared file
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.pookie1.shared"
        )?.appendingPathComponent("usageLimits.json"),
              let data = try? Data(contentsOf: url),
              let limits = try? JSONDecoder().decode([LimitConfig].self, from: data)
        else { return }

        for limit in limits {
            guard let selData = limit.appSelectionData,
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selData)
            else { continue }

            // Match app tokens
            var matchedApps = Set<ApplicationToken>()
            for appToken in selection.applicationTokens {
                if appTokenDurations[appToken] != nil {
                    matchedApps.insert(appToken)
                }
            }
            for catToken in selection.categoryTokens {
                for (appToken, cats) in appToCatTokens {
                    if cats.contains(catToken) {
                        matchedApps.insert(appToken)
                    }
                }
            }

            // Sum duration
            var totalDuration: TimeInterval = 0
            for appToken in matchedApps {
                totalDuration += appTokenDurations[appToken] ?? 0
            }

            defaults?.set(totalDuration, forKey: "limitUsage_\(limit.id.uuidString)")
        }
    }
}
