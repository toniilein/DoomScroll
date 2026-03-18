import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

struct TotalActivityData {
    let totalDuration: TimeInterval
    let formattedDuration: String
    let brainRotScore: Int
    let totalPickups: Int
    let topApps: [AppUsageData]
    let allApps: [AppUsageData]
    let smartKPIs: SmartKPIs
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (TotalActivityData) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> TotalActivityData {
        var totalDuration: TimeInterval = 0
        var totalPickups = 0
        var appUsages: [AppUsageData] = []
        var reportDate: Date = .now

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                reportDate = segment.dateInterval.start
                totalDuration += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        let appName = appActivity.application.localizedDisplayName ?? "Unknown"
                        let appDuration = appActivity.totalActivityDuration
                        let pickups = appActivity.numberOfPickups
                        totalPickups += pickups

                        if appDuration > 0 {
                            appUsages.append(AppUsageData(
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

        appUsages.sort { $0.duration > $1.duration }
        let topApps = Array(appUsages.prefix(10))
        let score = BrainRotCalculator.score(totalMinutes: totalDuration / 60.0)
        let formatted = BrainRotCalculator.formatDuration(totalDuration)

        let smartKPIs = BrainRotCalculator.computeSmartKPIs(
            totalDuration: totalDuration,
            totalPickups: totalPickups,
            topApps: topApps,
            brainRotScore: score
        )

        // Save score per day using simple key-per-day (safe in extension, no JSON)
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dayKey = "score_" + dateFormatter.string(from: Calendar.current.startOfDay(for: reportDate))
        shared?.set(score, forKey: dayKey)

        // Only update "current" values for today — don't overwrite with historical data
        if Calendar.current.isDateInToday(reportDate) {
            shared?.set(score, forKey: "lastBrainRotScore")
            shared?.set(totalDuration / 60.0, forKey: "lastScreenTimeMinutes")
            shared?.set(totalPickups, forKey: "lastPickups")
        }
        shared?.synchronize()

        return TotalActivityData(
            totalDuration: totalDuration,
            formattedDuration: formatted,
            brainRotScore: score,
            totalPickups: totalPickups,
            topApps: topApps,
            allApps: appUsages,
            smartKPIs: smartKPIs
        )
    }
}
