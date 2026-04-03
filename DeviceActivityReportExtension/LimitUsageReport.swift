import DeviceActivity
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

// Data returned to the view
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

        // Load all limit configs from UserDefaults
        struct LimitConfig {
            let id: String
            let minutes: Int
            let enabled: Bool
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
                    id: id, minutes: mins, enabled: enabled, selection: selection
                ))
            }
        }

        // Process ALL data — build per-app-token duration maps
        var appTokenDurations: [ApplicationToken: TimeInterval] = [:]
        var catNameDurations: [String: TimeInterval] = [:]
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
                                appToCatTokens[appToken, default: []].insert(catToken)
                            }
                        }
                    }
                }
            }
        }

        // Write per-category usage to shared file (for limit editor)
        Self.writeCategoryUsageFile(catNameDurations)

        // Compute per-limit usage and apply shields
        var exceededCount = 0
        var activeCount = 0

        for config in limitConfigs {
            if config.enabled { activeCount += 1 }

            // Collect matching app tokens
            var matchedApps = Set<ApplicationToken>()
            for appToken in config.selection.applicationTokens {
                if appTokenDurations[appToken] != nil {
                    matchedApps.insert(appToken)
                }
            }
            for catToken in config.selection.categoryTokens {
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

    // MARK: - Category usage file (for limit editor)

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.pookie1.shared")
    }

    static func writeCategoryUsageFile(_ catNameDurations: [String: TimeInterval]) {
        guard let url = containerURL?.appendingPathComponent("categoryUsage.json") else { return }
        var dict: [String: Double] = [:]
        for (name, dur) in catNameDurations where dur > 0 {
            dict[name] = dur / 60.0 // store as minutes
        }
        if let jsonData = try? JSONEncoder().encode(dict) {
            try? jsonData.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Detail report (stub, kept for extension registration)

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
        return LimitUsageDetailData(
            totalDuration: 0, formattedDuration: "0m",
            limitMinutes: 60, exceeded: false, progress: 0, categories: []
        )
    }
}
