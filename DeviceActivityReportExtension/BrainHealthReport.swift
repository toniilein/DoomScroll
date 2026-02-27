import DeviceActivity
import SwiftUI

struct BrainHealthData {
    let totalDuration: TimeInterval
    let brainRotScore: Int
    let formattedDuration: String
    let totalPickups: Int
    let longestSessionMinutes: Int
    let topApps: [AppUsageData]
}

struct BrainHealthReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .brainHealth
    let content: (BrainHealthData) -> BrainHealthReportView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> BrainHealthData {
        var totalDuration: TimeInterval = 0
        var totalPickups = 0
        var longestSession: TimeInterval = 0
        var appUsages: [AppUsageData] = []

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        let appName = appActivity.application.localizedDisplayName ?? "Unknown App"
                        let appDuration = appActivity.totalActivityDuration
                        let pickups = appActivity.numberOfPickups
                        totalPickups += pickups

                        if appDuration > longestSession {
                            longestSession = appDuration
                        }

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
        let topApps = Array(appUsages.prefix(5))

        let totalMinutes = totalDuration / 60.0
        let score = BrainRotCalculator.score(totalMinutes: totalMinutes)
        let formatted = BrainRotCalculator.formatDuration(totalDuration)
        let longestMins = Int(longestSession / 60.0)

        return BrainHealthData(
            totalDuration: totalDuration,
            brainRotScore: score,
            formattedDuration: formatted,
            totalPickups: totalPickups,
            longestSessionMinutes: longestMins,
            topApps: topApps
        )
    }
}
