import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

struct UsageSummaryData: Sendable {
    let totalDuration: TimeInterval
    let formattedDuration: String
    let categories: [CategorySummaryItem]
}

struct CategorySummaryItem: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let formattedDuration: String
}

struct UsageSummaryReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .usageSummary
    let content: (UsageSummaryData) -> UsageSummaryView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> UsageSummaryData {
        var totalDuration: TimeInterval = 0
        var categoryDurations: [String: TimeInterval] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration

                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? "Other"
                    for await appActivity in categoryActivity.applications {
                        let appDuration = appActivity.totalActivityDuration
                        if appDuration > 0 {
                            categoryDurations[catName, default: 0] += appDuration
                        }
                    }
                }
            }
        }

        // Save total to shared UserDefaults
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        shared?.set(totalDuration / 60.0, forKey: "lastScreenTimeMinutes")
        shared?.synchronize()

        let sortedCats = categoryDurations
            .sorted { $0.value > $1.value }
            .map { CategorySummaryItem(name: $0.key, duration: $0.value, formattedDuration: BrainRotCalculator.formatDuration($0.value)) }

        return UsageSummaryData(
            totalDuration: totalDuration,
            formattedDuration: BrainRotCalculator.formatDuration(totalDuration),
            categories: sortedCats
        )
    }
}
