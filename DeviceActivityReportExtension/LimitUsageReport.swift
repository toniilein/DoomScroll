import DeviceActivity
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

// Per-category usage
struct CategoryUsageItem: Sendable {
    let name: String
    let duration: TimeInterval
}

// Per-limit usage info passed to the view
struct LimitUsageItem: Sendable {
    let id: String
    let name: String
    let usedSeconds: Double
    let limitMinutes: Int
    let isEnabled: Bool
}

// Data returned to the view
struct LimitUsageData: Sendable {
    let categories: [CategoryUsageItem]
    let totalDuration: TimeInterval
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

        // 1. Process ALL activity data first — categories + token tracking
        var categoryDurations: [String: TimeInterval] = [:]
        var totalDuration: TimeInterval = 0
        var appTokenDurations: [ApplicationToken: TimeInterval] = [:]
        var appToCatTokens: [ApplicationToken: Set<ActivityCategoryToken>] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration
                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? "Other"
                    let catToken = categoryActivity.category.token
                    for await appActivity in categoryActivity.applications {
                        let dur = appActivity.totalActivityDuration
                        if dur > 0 {
                            categoryDurations[catName, default: 0] += dur
                            if let appToken = appActivity.application.token {
                                appTokenDurations[appToken, default: 0] += dur
                                if let catToken {
                                    appToCatTokens[appToken, default: []].insert(catToken)
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Read limits from shared FILE and compute per-limit usage
        let limits = Self.readLimitsFromFile()
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        var items: [LimitUsageItem] = []
        var exceededCount = 0

        for limit in limits {
            guard limit.limitMinutes > 0,
                  let selData = limit.appSelectionData,
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selData)
            else { continue }

            let activeDays = limit.activeDays ?? [1, 2, 3, 4, 5, 6, 7]
            let activeToday = activeDays.contains(todayWeekday)

            // Match app tokens from selection
            var matchedApps = Set<ApplicationToken>()
            for appToken in selection.applicationTokens {
                if appTokenDurations[appToken] != nil {
                    matchedApps.insert(appToken)
                }
            }
            for catToken in selection.categoryTokens {
                for (appToken, cats) in appToCatTokens {
                    if cats.contains(catToken) {
                        matchedApps.insert(appToken)
                    }
                }
            }

            var limitDuration: TimeInterval = 0
            for appToken in matchedApps {
                limitDuration += appTokenDurations[appToken] ?? 0
            }

            let usedMinutes = limitDuration / 60.0
            let exceeded = usedMinutes >= Double(limit.limitMinutes)
            if exceeded && limit.isEnabled && activeToday { exceededCount += 1 }

            // Apply/remove shield
            let store = ManagedSettingsStore(named: .init("limit_\(limit.id.uuidString)"))
            if limit.isEnabled && activeToday && exceeded {
                if !selection.applicationTokens.isEmpty {
                    store.shield.applications = selection.applicationTokens
                }
                if !selection.categoryTokens.isEmpty {
                    store.shield.applicationCategories = .specific(selection.categoryTokens)
                }
            } else if !limit.isEnabled || !activeToday {
                store.clearAllSettings()
            }

            items.append(LimitUsageItem(
                id: limit.id.uuidString,
                name: limit.name,
                usedSeconds: limitDuration,
                limitMinutes: limit.limitMinutes,
                isEnabled: limit.isEnabled
            ))
        }

        // Write usage data to shared UserDefaults so native cards can display it
        Self.writeUsageToDefaults(items)

        return LimitUsageData(
            categories: [],
            totalDuration: totalDuration,
            items: items,
            exceededCount: exceededCount
        )
    }

    /// Writes per-limit usage to shared UserDefaults for the native UI to read.
    private static func writeUsageToDefaults(_ items: [LimitUsageItem]) {
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        // Mark that makeConfiguration ran
        shared?.set(Date().timeIntervalSince1970, forKey: "report_lastRun")
        shared?.set(items.count, forKey: "report_itemCount")

        for item in items {
            let usedMinutes = Int(item.usedSeconds / 60.0)
            // Write per-limit usage (same key the monitor uses)
            let currentProgress = shared?.integer(forKey: "limitProgress_\(item.id)") ?? 0
            // Report has exact data — always overwrite if higher or if we have real data
            if usedMinutes > 0 || currentProgress == 0 {
                shared?.set(usedMinutes, forKey: "limitProgress_\(item.id)")
                shared?.set(Date().timeIntervalSince1970, forKey: "limitProgressTime_\(item.id)")
            }
        }
        shared?.synchronize()
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
