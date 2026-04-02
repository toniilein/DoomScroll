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

// Codable limit model (mirrors UsageLimit from main app, decoded in extension)
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
        // Read limits from shared file (reliable cross-process)
        let limits = Self.readLimitsFromFile()

        // Process ALL data
        var appTokenDurations: [ApplicationToken: TimeInterval] = [:]
        var catTokenDurations: [ActivityCategoryToken: TimeInterval] = [:]
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
                                catTokenDurations[catToken, default: 0] += dur
                                appToCatTokens[appToken, default: []].insert(catToken)
                            }
                        }
                    }
                }
            }
        }

        // Write per-category usage to shared file (for editor)
        Self.writeCategoryUsageFile(catNameDurations)

        // Compute per-limit usage and apply shields
        var exceededCount = 0
        var activeCount = 0
        var limitResults: [String: Double] = [:]

        for limit in limits {
            let selection: FamilyActivitySelection
            if let data = limit.appSelectionData,
               let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                selection = sel
            } else {
                continue
            }

            if limit.isEnabled { activeCount += 1 }

            // Collect matching app tokens
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

            // Sum unique durations
            var limitDuration: TimeInterval = 0
            for appToken in matchedApps {
                limitDuration += appTokenDurations[appToken] ?? 0
            }

            let idStr = limit.id.uuidString
            limitResults[idStr] = limitDuration

            let usedMinutes = limitDuration / 60.0
            let exceeded = usedMinutes >= Double(limit.limitMinutes)
            if exceeded && limit.isEnabled { exceededCount += 1 }

            // Apply/remove shield
            let store = ManagedSettingsStore(named: .init("limit_\(idStr)"))
            if limit.isEnabled && exceeded {
                if !selection.applicationTokens.isEmpty {
                    store.shield.applications = selection.applicationTokens
                }
                if !selection.categoryTokens.isEmpty {
                    store.shield.applicationCategories = .specific(selection.categoryTokens)
                }
            } else if !limit.isEnabled {
                store.clearAllSettings()
            }
        }

        // Write per-limit usage to shared file
        Self.writeLimitUsageFile(limitResults)

        return LimitUsageData(
            exceededCount: exceededCount,
            activeCount: activeCount,
            totalCount: limits.count
        )
    }

    // MARK: - File-based cross-process communication

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

    static func writeLimitUsageFile(_ results: [String: Double]) {
        guard let url = containerURL?.appendingPathComponent("limitUsage.json") else { return }
        // Store as seconds
        if let jsonData = try? JSONEncoder().encode(results) {
            try? jsonData.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Detail report (kept for backward compat, unused by editor now)

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
