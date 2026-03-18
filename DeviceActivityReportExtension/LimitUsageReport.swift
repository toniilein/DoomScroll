import DeviceActivity
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

struct LimitUsageData: Sendable {
    let totalDuration: TimeInterval
    let formattedDuration: String
    let limitMinutes: Int
    let exceeded: Bool
    let progress: Double
}

struct LimitUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitUsage
    let content: (LimitUsageData) -> LimitUsageView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> LimitUsageData {
        // Sum durations from individual apps (filter already scopes to selected apps)
        var totalDuration: TimeInterval = 0

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        let dur = appActivity.totalActivityDuration
                        if dur > 0 {
                            totalDuration += dur
                        }
                    }
                }
            }
        }

        // Read limit config written by main app
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        shared?.synchronize()

        let limitId = shared?.string(forKey: "activeLimitId") ?? ""
        let limitMinutes = shared?.integer(forKey: "activeLimitMinutes") ?? 60
        let isEnabled = shared?.bool(forKey: "activeLimitEnabled") ?? true

        let usedMinutes = totalDuration / 60.0
        let exceeded = usedMinutes >= Double(limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, limitMinutes)))

        // Apply or clear shield based on state
        if !limitId.isEmpty {
            let store = ManagedSettingsStore(named: .init("limit_\(limitId)"))

            if isEnabled && exceeded {
                // Decode the limit's FamilyActivitySelection and apply shield
                if let selData = shared?.data(forKey: "activeLimitSelectionData"),
                   let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selData) {
                    if !selection.applicationTokens.isEmpty {
                        store.shield.applications = selection.applicationTokens
                    }
                    if !selection.categoryTokens.isEmpty {
                        store.shield.applicationCategories = .specific(selection.categoryTokens)
                    }
                }
            } else if !isEnabled {
                // User disabled the limit — clear shield
                store.clearAllSettings()
            }
        }

        return LimitUsageData(
            totalDuration: totalDuration,
            formattedDuration: BrainRotCalculator.formatDuration(totalDuration),
            limitMinutes: limitMinutes,
            exceeded: exceeded,
            progress: progress
        )
    }
}
