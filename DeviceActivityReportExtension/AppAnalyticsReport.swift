import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

struct AppAnalyticsData {
    let allApps: [AppUsageData]
    let totalDuration: TimeInterval
    let formattedTotalDuration: String
    let totalPickups: Int
    let appCount: Int
}

struct AppAnalyticsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .appAnalytics
    let content: (AppAnalyticsData) -> AppAnalyticsView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> AppAnalyticsData {
        var totalDuration: TimeInterval = 0
        var totalPickups = 0
        var appUsages: [AppUsageData] = []

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? "Other"
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
                                numberOfPickups: pickups,
                                categoryName: catName
                            ))
                        }
                    }
                }
            }
        }

        // Sort by duration descending — keep ALL apps
        appUsages.sort { $0.duration > $1.duration }
        let formatted = BrainRotCalculator.formatDuration(totalDuration)

        return AppAnalyticsData(
            allApps: appUsages,
            totalDuration: totalDuration,
            formattedTotalDuration: formatted,
            totalPickups: totalPickups,
            appCount: appUsages.count
        )
    }
}
