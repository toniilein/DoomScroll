import DeviceActivity
import SwiftUI

struct ActivityReportData {
    let totalDuration: TimeInterval
    let brainRotScore: Int
    let formattedDuration: String
    let topApps: [AppUsageData]
}

struct AppUsageData: Identifiable {
    let id = UUID()
    let displayName: String
    let duration: TimeInterval
    let formattedDuration: String
    let numberOfPickups: Int
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReportData) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> ActivityReportData {
        var totalDuration: TimeInterval = 0
        var appUsages: [AppUsageData] = []

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        let appName = appActivity.application.localizedDisplayName ?? "Unknown App"
                        let appDuration = appActivity.totalActivityDuration
                        let pickups = appActivity.numberOfPickups

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

        let totalMinutes = totalDuration / 60.0
        let score = BrainRotCalculator.score(totalMinutes: totalMinutes)
        let formatted = BrainRotCalculator.formatDuration(totalDuration)

        return ActivityReportData(
            totalDuration: totalDuration,
            brainRotScore: score,
            formattedDuration: formatted,
            topApps: topApps
        )
    }
}
