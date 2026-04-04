import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DoomScrollMonitorExtension: DeviceActivityMonitor {

    let sharedSuiteName = "group.pookie1.shared"

    private var shared: UserDefaults? {
        UserDefaults(suiteName: sharedSuiteName)
    }

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedSuiteName)
    }

    /// Write usage to limitUsage.json file (more reliable cross-process than UserDefaults)
    private func writeUsageToFile(id: String, minutes: Int) {
        guard let fileURL = containerURL?.appendingPathComponent("limitUsage.json") else { return }
        var existing: [String: Int] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let dict = try? JSONDecoder().decode([String: Int].self, from: data) {
            existing = dict
        }
        existing[id] = max(minutes, existing[id] ?? 0)
        if let data = try? JSONEncoder().encode(existing) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Routine schedule callbacks

    override func intervalDidStart(for activity: DeviceActivityName) {
        let raw = activity.rawValue

        // Log that monitoring is active
        shared?.set(Date().timeIntervalSince1970, forKey: "monitor_lastIntervalStart_\(raw)")
        shared?.synchronize()

        if raw.hasPrefix("routine_") {
            let id = String(raw.dropFirst("routine_".count))
            applyRoutineShield(id: id)
        }
        if raw.hasPrefix("limit_") {
            // Reset usage progress at start of new interval (new day)
            let id = String(raw.dropFirst("limit_".count))
            shared?.set(0, forKey: "limitProgress_\(id)")
            shared?.set(Date().timeIntervalSince1970, forKey: "limitProgressTime_\(id)")
            shared?.synchronize()
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        let raw = activity.rawValue
        if raw.hasPrefix("routine_") {
            let id = String(raw.dropFirst("routine_".count))
            let store = ManagedSettingsStore(named: .init("routine_\(id)"))
            store.clearAllSettings()
        }
        if raw.hasPrefix("limit_") {
            // Daily reset: clear shield and usage progress
            let id = String(raw.dropFirst("limit_".count))
            let store = ManagedSettingsStore(named: .init("limit_\(id)"))
            store.clearAllSettings()
            shared?.set(0, forKey: "limitProgress_\(id)")
            shared?.synchronize()
        }
    }

    // MARK: - Usage limit threshold callback

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        let raw = event.rawValue

        // Log every threshold hit for diagnostics
        shared?.set(Date().timeIntervalSince1970, forKey: "monitor_lastThreshold")
        shared?.set(raw, forKey: "monitor_lastThresholdEvent")
        shared?.synchronize()

        // Event naming: "limit_<UUID>" for final shield, "limitprog_<UUID>_<minutes>" for progress
        if raw.hasPrefix("limitprog_") {
            // Progress event: "limitprog_<UUID>_<minutes>"
            let suffix = String(raw.dropFirst("limitprog_".count))
            // UUID is 36 chars (with hyphens), then "_", then minutes
            if suffix.count > 37 {
                let id = String(suffix.prefix(36))
                let minuteStr = String(suffix.dropFirst(37))
                if let minutes = Int(minuteStr) {
                    // Write progress to UserDefaults
                    let current = shared?.integer(forKey: "limitProgress_\(id)") ?? 0
                    if minutes > current {
                        shared?.set(minutes, forKey: "limitProgress_\(id)")
                        shared?.set(Date().timeIntervalSince1970, forKey: "limitProgressTime_\(id)")
                        shared?.synchronize()
                        writeUsageToFile(id: id, minutes: minutes)
                    }
                }
            }
        } else if raw.hasPrefix("limit_") {
            // Final threshold: apply shield
            let id = String(raw.dropFirst("limit_".count))
            applyLimitShield(id: id)

            // Also update progress to the limit value
            let limits = loadLimits()
            if let limit = limits.first(where: { $0.id.uuidString == id }) {
                shared?.set(limit.limitMinutes, forKey: "limitProgress_\(id)")
                shared?.set(Date().timeIntervalSince1970, forKey: "limitProgressTime_\(id)")
                shared?.synchronize()
                writeUsageToFile(id: id, minutes: limit.limitMinutes)
            }
        }
    }

    // MARK: - Apply shields

    private func applyRoutineShield(id: String) {
        let routines = loadRoutines()
        guard let routine = routines.first(where: { $0.id.uuidString == id }),
              routine.isEnabled,
              let selectionData = routine.appSelectionData,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData) else { return }

        let store = ManagedSettingsStore(named: .init("routine_\(id)"))
        if !selection.applicationTokens.isEmpty { store.shield.applications = selection.applicationTokens }
        if !selection.categoryTokens.isEmpty { store.shield.applicationCategories = .specific(selection.categoryTokens) }
        if !selection.webDomainTokens.isEmpty { store.shield.webDomains = selection.webDomainTokens }
    }

    private func applyLimitShield(id: String) {
        let limits = loadLimits()
        guard let limit = limits.first(where: { $0.id.uuidString == id }),
              limit.isEnabled,
              let selectionData = limit.appSelectionData,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData) else { return }

        let store = ManagedSettingsStore(named: .init("limit_\(id)"))
        if !selection.applicationTokens.isEmpty { store.shield.applications = selection.applicationTokens }
        if !selection.categoryTokens.isEmpty { store.shield.applicationCategories = .specific(selection.categoryTokens) }
        if !selection.webDomainTokens.isEmpty { store.shield.webDomains = selection.webDomainTokens }
    }

    // MARK: - Load data from shared UserDefaults

    private func loadRoutines() -> [BlockRoutineData] {
        guard let defaults = shared,
              let data = defaults.data(forKey: "blockRoutines"),
              let routines = try? JSONDecoder().decode([BlockRoutineData].self, from: data) else { return [] }
        return routines
    }

    private func loadLimits() -> [UsageLimitData] {
        guard let defaults = shared,
              let data = defaults.data(forKey: "usageLimits"),
              let limits = try? JSONDecoder().decode([UsageLimitData].self, from: data) else { return [] }
        return limits
    }
}

// Minimal decodable structs (avoids importing host app module)

private struct BlockRoutineData: Codable, Identifiable {
    var id: UUID
    var name: String
    var appSelectionData: Data?
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool
    var createdAt: Date
}

private struct UsageLimitData: Codable, Identifiable {
    var id: UUID
    var name: String
    var appSelectionData: Data?
    var limitMinutes: Int
    var isEnabled: Bool
    var activeDays: Set<Int>?
}
