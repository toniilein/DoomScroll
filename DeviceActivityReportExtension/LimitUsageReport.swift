import DeviceActivity
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

// Data returned to the view — just a processing signal + summary
struct LimitUsageData: Sendable {
    let exceededCount: Int
    let activeCount: Int
    let totalCount: Int
}

// MARK: - Single report that processes ALL limits at once

struct LimitUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitUsage
    let content: (LimitUsageData) -> LimitUsageView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> LimitUsageData {
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        shared?.synchronize()

        let allLimitIds = shared?.stringArray(forKey: "allLimitIds") ?? []

        // Load all limit configs
        struct LimitConfig {
            let id: String
            let minutes: Int
            let enabled: Bool
            let appTokens: Set<ApplicationToken>
            let catTokens: Set<ActivityCategoryToken>
            let selection: FamilyActivitySelection
        }

        var limitConfigs: [LimitConfig] = []
        for id in allLimitIds {
            let mins = shared?.integer(forKey: "limit_\(id)_minutes") ?? 0
            guard mins > 0 else { continue }
            let enabled = shared?.bool(forKey: "limit_\(id)_enabled") ?? false
            if let selData = shared?.data(forKey: "limit_\(id)_selectionData"),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selData) {
                limitConfigs.append(LimitConfig(
                    id: id, minutes: mins, enabled: enabled,
                    appTokens: selection.applicationTokens,
                    catTokens: selection.categoryTokens,
                    selection: selection
                ))
            }
        }

        // Process ALL data — build per-app-token and per-category-token duration maps
        var appTokenDurations: [ApplicationToken: TimeInterval] = [:]
        var catTokenDurations: [ActivityCategoryToken: TimeInterval] = [:]
        var catNameDurations: [String: TimeInterval] = [:]
        // Track which apps belong to which categories (for deduplication)
        var appToCatTokens: [ApplicationToken: Set<ActivityCategoryToken>] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                for await categoryActivity in segment.categories {
                    let catToken = categoryActivity.category.token
                    let catName = categoryActivity.category.localizedDisplayName ?? "Other"
                    for await appActivity in categoryActivity.applications {
                        let dur = appActivity.totalActivityDuration
                        if dur > 0, let appToken = appActivity.application.token {
                            appTokenDurations[appToken, default: 0] += dur
                            catNameDurations[catName, default: 0] += dur
                            if let catToken {
                                catTokenDurations[catToken, default: 0] += dur
                                appToCatTokens[appToken, default: []].insert(catToken)
                            }
                        }
                    }
                }
            }
        }

        // Write per-category usage to a shared JSON file (reliable cross-process)
        var catUsageDict: [String: Double] = [:]
        for (name, dur) in catNameDurations where dur > 0 {
            catUsageDict[name] = dur
        }
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.pookie1.shared"
        ) {
            let fileURL = containerURL.appendingPathComponent("categoryUsage.json")
            if let jsonData = try? JSONEncoder().encode(catUsageDict) {
                try? jsonData.write(to: fileURL, options: .atomic)
            }
        }

        // Compute per-limit usage and apply shields
        var exceededCount = 0
        var activeCount = 0

        for config in limitConfigs {
            if config.enabled { activeCount += 1 }

            // Collect all matching app tokens (union of direct apps + apps in selected categories)
            var matchedApps = Set<ApplicationToken>()

            // Add directly selected app tokens
            for appToken in config.appTokens {
                if appTokenDurations[appToken] != nil {
                    matchedApps.insert(appToken)
                }
            }

            // Add apps from selected categories
            for catToken in config.catTokens {
                for (appToken, cats) in appToCatTokens {
                    if cats.contains(catToken) {
                        matchedApps.insert(appToken)
                    }
                }
            }

            // Sum unique app durations
            var limitDuration: TimeInterval = 0
            for appToken in matchedApps {
                limitDuration += appTokenDurations[appToken] ?? 0
            }

            // Write to shared UserDefaults (simple Double — works cross-process)
            shared?.set(limitDuration, forKey: "limit_\(config.id)_usedSeconds")

            let usedMinutes = limitDuration / 60.0
            let exceeded = usedMinutes >= Double(config.minutes)

            if exceeded && config.enabled { exceededCount += 1 }

            // Apply/remove shield
            let store = ManagedSettingsStore(named: .init("limit_\(config.id)"))
            if config.enabled && exceeded {
                if !config.selection.applicationTokens.isEmpty {
                    store.shield.applications = config.selection.applicationTokens
                }
                if !config.selection.categoryTokens.isEmpty {
                    store.shield.applicationCategories = .specific(config.selection.categoryTokens)
                }
            } else if !config.enabled {
                store.clearAllSettings()
            }
        }

        shared?.synchronize()

        return LimitUsageData(
            exceededCount: exceededCount,
            activeCount: activeCount,
            totalCount: limitConfigs.count
        )
    }
}

// MARK: - Detail report (Editor sheet) — kept for LimitEditorView

struct LimitCategoryInfo: Sendable {
    let name: String
    let duration: TimeInterval
    let formattedDuration: String
}

struct LimitUsageDetailData: Sendable {
    let totalDuration: TimeInterval
    let formattedDuration: String
    let limitMinutes: Int
    let exceeded: Bool
    let progress: Double
    let categories: [LimitCategoryInfo]
}

struct LimitUsageDetailReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitUsageDetail
    let content: (LimitUsageDetailData) -> LimitUsageDetailView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> LimitUsageDetailData {
        var totalDuration: TimeInterval = 0
        var categoryDurations: [String: TimeInterval] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? "Other"
                    for await appActivity in categoryActivity.applications {
                        let dur = appActivity.totalActivityDuration
                        if dur > 0 {
                            totalDuration += dur
                            categoryDurations[catName, default: 0] += dur
                        }
                    }
                }
            }
        }

        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        shared?.synchronize()
        let limitMinutes = shared?.integer(forKey: "detailLimitMinutes") ?? 60

        let usedMinutes = totalDuration / 60.0
        let exceeded = usedMinutes >= Double(limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, limitMinutes)))

        // Only include categories with actual usage
        let cats = categoryDurations
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { LimitCategoryInfo(
                name: $0.key,
                duration: $0.value,
                formattedDuration: BrainRotCalculator.formatDuration($0.value)
            ) }

        // Write category count so the main app can size the frame
        shared?.set(cats.count, forKey: "detailCategoryCount")
        shared?.synchronize()

        return LimitUsageDetailData(
            totalDuration: totalDuration,
            formattedDuration: BrainRotCalculator.formatDuration(totalDuration),
            limitMinutes: limitMinutes,
            exceeded: exceeded,
            progress: progress,
            categories: cats
        )
    }
}
