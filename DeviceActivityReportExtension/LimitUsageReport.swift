import DeviceActivity
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

// Per-limit usage info passed to the view
struct LimitUsageItem: Sendable {
    let id: String
    let name: String
    let usedSeconds: Double
    let limitMinutes: Int
    let isEnabled: Bool
}

// Data returned to the view — includes per-limit breakdown
struct LimitUsageData: Sendable {
    let items: [LimitUsageItem]
    let exceededCount: Int
}

// Must match what the main app writes to usageLimits.json
fileprivate struct CodableLimit: Codable {
    let id: UUID
    let name: String
    let appSelectionData: Data?
    let limitMinutes: Int
    let isEnabled: Bool
    let activeDays: Set<Int>?
}

// MARK: - Single report that processes ALL limits at once

struct LimitUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitUsage
    let content: (LimitUsageData) -> LimitUsageView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> LimitUsageData {
        // Read limits from shared FILE (extension can read but not write)
        let limits = Self.readLimitsFromFile()

        struct LimitConfig {
            let id: String
            let name: String
            let minutes: Int
            let enabled: Bool
            let activeToday: Bool
            let selection: FamilyActivitySelection
        }

        let todayWeekday = Calendar.current.component(.weekday, from: Date()) // 1=Sun..7=Sat
        var limitConfigs: [LimitConfig] = []
        for limit in limits {
            guard limit.limitMinutes > 0,
                  let selData = limit.appSelectionData,
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selData)
            else { continue }
            let activeDays = limit.activeDays ?? [1, 2, 3, 4, 5, 6, 7]
            limitConfigs.append(LimitConfig(
                id: limit.id.uuidString,
                name: limit.name,
                minutes: limit.limitMinutes,
                enabled: limit.isEnabled,
                activeToday: activeDays.contains(todayWeekday),
                selection: selection
            ))
        }

        // Process ALL activity data
        var appTokenDurations: [ApplicationToken: TimeInterval] = [:]
        var appToCatTokens: [ApplicationToken: Set<ActivityCategoryToken>] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                for await categoryActivity in segment.categories {
                    let catToken = categoryActivity.category.token
                    for await appActivity in categoryActivity.applications {
                        let dur = appActivity.totalActivityDuration
                        if dur > 0, let appToken = appActivity.application.token {
                            appTokenDurations[appToken, default: 0] += dur
                            if let catToken {
                                appToCatTokens[appToken, default: []].insert(catToken)
                            }
                        }
                    }
                }
            }
        }

        // Compute per-limit usage
        var items: [LimitUsageItem] = []
        var exceededCount = 0

        for config in limitConfigs {
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

            let usedMinutes = limitDuration / 60.0
            let exceeded = usedMinutes >= Double(config.minutes)
            if exceeded && config.enabled && config.activeToday { exceededCount += 1 }

            // Apply/remove shield (only enforce on active days)
            let store = ManagedSettingsStore(named: .init("limit_\(config.id)"))
            if config.enabled && config.activeToday && exceeded {
                if !config.selection.applicationTokens.isEmpty {
                    store.shield.applications = config.selection.applicationTokens
                }
                if !config.selection.categoryTokens.isEmpty {
                    store.shield.applicationCategories = .specific(config.selection.categoryTokens)
                }
            } else if !config.enabled || !config.activeToday {
                store.clearAllSettings()
            }

            items.append(LimitUsageItem(
                id: config.id,
                name: config.name,
                usedSeconds: limitDuration,
                limitMinutes: config.minutes,
                isEnabled: config.enabled
            ))

            // Write per-limit usage to shared UserDefaults so main app can display it
            let shared = UserDefaults(suiteName: "group.pookie1.shared")
            shared?.set(limitDuration, forKey: "limitUsage_\(config.id)")
        }

        return LimitUsageData(items: items, exceededCount: exceededCount)
    }

    // MARK: - File I/O

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
