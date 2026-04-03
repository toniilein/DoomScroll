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

// Must match what the main app writes to usageLimits.json
fileprivate struct CodableLimit: Codable {
    let id: UUID
    let name: String
    let appSelectionData: Data?
    let limitMinutes: Int
    let isEnabled: Bool
}

// MARK: - Single report that processes ALL limits at once

struct LimitUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitUsage
    let content: (LimitUsageData) -> LimitUsageView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> LimitUsageData {
        // Read limits from shared FILE (UserDefaults is broken in extensions)
        let limits = Self.readLimitsFromFile()

        struct LimitConfig {
            let id: String
            let minutes: Int
            let enabled: Bool
            let selection: FamilyActivitySelection
        }

        var limitConfigs: [LimitConfig] = []
        for limit in limits {
            guard limit.limitMinutes > 0,
                  let selData = limit.appSelectionData,
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selData)
            else { continue }
            limitConfigs.append(LimitConfig(
                id: limit.id.uuidString,
                minutes: limit.limitMinutes,
                enabled: limit.isEnabled,
                selection: selection
            ))
        }

        // Process ALL activity data
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

        // Write per-category usage to file (for limit editor)
        Self.writeCategoryUsageFile(catNameDurations)

        // Compute per-limit usage
        var exceededCount = 0
        var activeCount = 0
        var limitUsageResults: [String: Double] = [:]

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

            limitUsageResults[config.id] = limitDuration

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

        // Write usage results to file (UserDefaults broken in extensions)
        Self.writeLimitUsageFile(limitUsageResults)

        return LimitUsageData(
            exceededCount: exceededCount,
            activeCount: activeCount,
            totalCount: limitConfigs.count
        )
    }

    // MARK: - File I/O (app group container — proven reliable cross-process)

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.pookie1.shared")
    }

    fileprivate static func readLimitsFromFile() -> [CodableLimit] {
        guard let url = containerURL?.appendingPathComponent("usageLimits.json"),
              let data = try? Data(contentsOf: url),
              let limits = try? JSONDecoder().decode([CodableLimit].self, from: data) else {
            return []
        }
        return limits
    }

    static func writeLimitUsageFile(_ results: [String: Double]) {
        guard let url = containerURL?.appendingPathComponent("limitUsage.json") else { return }
        if let jsonData = try? JSONEncoder().encode(results) {
            try? jsonData.write(to: url, options: .atomic)
        }
    }

    static func writeCategoryUsageFile(_ catNameDurations: [String: TimeInterval]) {
        guard let url = containerURL?.appendingPathComponent("categoryUsage.json") else { return }
        var dict: [String: Double] = [:]
        for (name, dur) in catNameDurations where dur > 0 {
            dict[name] = dur / 60.0
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
