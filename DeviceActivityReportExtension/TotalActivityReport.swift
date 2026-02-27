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

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
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

        return TotalActivityData(
            totalDuration: totalDuration,
            formattedDuration: formatted,
            brainRotScore: score,
            totalPickups: totalPickups,
            topApps: topApps,
            smartKPIs: smartKPIs
        )
    }
}
