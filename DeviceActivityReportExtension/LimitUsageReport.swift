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
struct CodableLimit: Codable {
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

    static func readLimitsFromFile() -> [CodableLimit] {
        guard let url = containerURL?.appendingPathComponent("usageLimits.json"),
              let data = try? Data(contentsOf: url),
              let limits = try? JSONDecoder().decode([CodableLimit].self, from: data) else {
            return []
        }
        return limits
    }
}

// MARK: - Per-limit slot reports (one bar per limit card)

/// Data for a single limit bar
struct SingleLimitData: Sendable {
    let id: String
    let name: String
    let usedSeconds: Double
    let limitMinutes: Int
    let isEmpty: Bool
}

/// View for a single limit usage bar
struct SingleLimitBarView: View {
    let data: SingleLimitData

    var body: some View {
        let usedMinutes = data.usedSeconds / 60.0
        let limitMins = data.isEmpty ? 60 : data.limitMinutes
        let exceeded = !data.isEmpty && usedMinutes >= Double(limitMins)
        let progress = data.isEmpty ? 0.0 : min(1.0, usedMinutes / Double(max(1, limitMins)))

        let textPrimary = Color(red: 0.239, green: 0.224, blue: 0.161)
        let textSecondary = Color(red: 0.549, green: 0.522, blue: 0.467)
        let barTrack = Color(red: 0.910, green: 0.898, blue: 0.863)
        let purple = Color(red: 0.608, green: 0.420, blue: 0.769)

        VStack(spacing: 8) {
            HStack {
                if exceeded {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("\(formatDuration(data.usedSeconds)) / \(formatMinutes(limitMins))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                } else if usedMinutes > 0 {
                    Text("\(formatDuration(data.usedSeconds)) used")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(textPrimary)
                } else {
                    Text("0m used")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(textSecondary)
                }

                Spacer()

                if exceeded {
                    Text("Exceeded")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                } else {
                    let remaining = max(0, Double(limitMins) - usedMinutes)
                    Text("\(formatDuration(remaining * 60)) left")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(usedMinutes > 0 ? purple : textSecondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barTrack)
                    if progress > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(exceeded ? Color.red : purple)
                            .frame(width: max(4, geo.size.width * progress))
                    }
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color(red: 0.957, green: 0.953, blue: 0.933).opacity(0.6))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

/// Shared logic for per-slot reports
struct LimitSlotHelper {
    static func makeConfig(
        slotIndex: Int,
        data: DeviceActivityResults<DeviceActivityData>
    ) async -> SingleLimitData {
        let limits = LimitUsageReport.readLimitsFromFile()
        guard slotIndex < limits.count else {
            return SingleLimitData(id: "", name: "", usedSeconds: 0, limitMinutes: 0, isEmpty: true)
        }

        let limit = limits[slotIndex]
        guard limit.limitMinutes > 0,
              let selData = limit.appSelectionData,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selData)
        else {
            return SingleLimitData(id: "", name: "", usedSeconds: 0, limitMinutes: 0, isEmpty: true)
        }

        // Collect per-app durations and per-category durations
        var appTokenDurations: [ApplicationToken: TimeInterval] = [:]
        var catTokenDurations: [ActivityCategoryToken: TimeInterval] = [:]
        var appToCatTokens: [ApplicationToken: Set<ActivityCategoryToken>] = [:]

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                for await categoryActivity in segment.categories {
                    let catToken = categoryActivity.category.token
                    var catDur: TimeInterval = 0
                    for await appActivity in categoryActivity.applications {
                        let dur = appActivity.totalActivityDuration
                        if let appToken = appActivity.application.token {
                            appTokenDurations[appToken, default: 0] += dur
                            if let catToken {
                                appToCatTokens[appToken, default: []].insert(catToken)
                            }
                            catDur += dur
                        }
                    }
                    if let catToken {
                        catTokenDurations[catToken, default: 0] += catDur
                    }
                }
            }
        }

        // Calculate duration: sum selected app tokens + selected category tokens
        var duration: TimeInterval = 0
        var countedApps = Set<ApplicationToken>()

        // Direct app selections
        for appToken in selection.applicationTokens {
            let dur = appTokenDurations[appToken] ?? 0
            duration += dur
            countedApps.insert(appToken)
        }

        // Category selections — add apps in those categories (avoid double-counting)
        for catToken in selection.categoryTokens {
            for (appToken, cats) in appToCatTokens {
                if cats.contains(catToken) && !countedApps.contains(appToken) {
                    duration += appTokenDurations[appToken] ?? 0
                    countedApps.insert(appToken)
                }
            }
        }

        // Apply/remove shield based on usage
        let usedMinutes = duration / 60.0
        let exceeded = usedMinutes >= Double(limit.limitMinutes)
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        let activeDays = limit.activeDays ?? [1, 2, 3, 4, 5, 6, 7]
        let activeToday = activeDays.contains(todayWeekday)

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

        return SingleLimitData(
            id: limit.id.uuidString, name: limit.name,
            usedSeconds: duration, limitMinutes: limit.limitMinutes, isEmpty: false
        )
    }
}

struct LimitSlot0Report: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitSlot0
    let content: (SingleLimitData) -> SingleLimitBarView
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SingleLimitData {
        await LimitSlotHelper.makeConfig(slotIndex: 0, data: data)
    }
}
struct LimitSlot1Report: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitSlot1
    let content: (SingleLimitData) -> SingleLimitBarView
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SingleLimitData {
        await LimitSlotHelper.makeConfig(slotIndex: 1, data: data)
    }
}
struct LimitSlot2Report: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitSlot2
    let content: (SingleLimitData) -> SingleLimitBarView
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SingleLimitData {
        await LimitSlotHelper.makeConfig(slotIndex: 2, data: data)
    }
}
struct LimitSlot3Report: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitSlot3
    let content: (SingleLimitData) -> SingleLimitBarView
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SingleLimitData {
        await LimitSlotHelper.makeConfig(slotIndex: 3, data: data)
    }
}
struct LimitSlot4Report: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .limitSlot4
    let content: (SingleLimitData) -> SingleLimitBarView
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SingleLimitData {
        await LimitSlotHelper.makeConfig(slotIndex: 4, data: data)
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
