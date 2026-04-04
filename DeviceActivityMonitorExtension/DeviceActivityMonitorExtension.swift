import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DoomScrollMonitorExtension: DeviceActivityMonitor {

    let sharedSuiteName = "group.pookie1.shared"

    // MARK: - Routine schedule callbacks

    override func intervalDidStart(for activity: DeviceActivityName) {
        let raw = activity.rawValue
        if raw.hasPrefix("routine_") {
            let id = String(raw.dropFirst("routine_".count))
            applyRoutineShield(id: id)
        }
        // limit_ activities: shield applied via eventDidReachThreshold
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        let raw = activity.rawValue
        if raw.hasPrefix("routine_") {
            let id = String(raw.dropFirst("routine_".count))
            let store = ManagedSettingsStore(named: .init("routine_\(id)"))
            store.clearAllSettings()
        }
        if raw.hasPrefix("limit_") {
            // Daily reset: clear the limit shield and usage progress
            let id = String(raw.dropFirst("limit_".count))
            let store = ManagedSettingsStore(named: .init("limit_\(id)"))
            store.clearAllSettings()
            clearUsageProgress(limitId: id)
        }
    }

    // MARK: - Usage limit threshold callback

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        let raw = event.rawValue
        if raw.hasPrefix("limit_") {
            // Parse event name: "limit_<UUID>_<minutes>" for progress, "limit_<UUID>" for final threshold
            let suffix = String(raw.dropFirst("limit_".count))
            let parts = suffix.split(separator: "_", maxSplits: 1)

            if parts.count == 1 {
                // Final threshold: "limit_<UUID>" — apply shield
                let id = String(parts[0])
                applyLimitShield(id: id)
                // Also write progress
                writeUsageProgress(limitId: id, minutesReached: nil)
            } else {
                // Progress threshold: "limit_<36-char-UUID>_<minutes>"
                // UUID is 36 chars, so split differently
                let uuidLength = 36
                if suffix.count > uuidLength + 1 {
                    let id = String(suffix.prefix(uuidLength))
                    let minuteStr = String(suffix.dropFirst(uuidLength + 1))
                    if let minutes = Int(minuteStr) {
                        writeUsageProgress(limitId: id, minutesReached: minutes)
                    }
                }
            }
        }
    }

    // MARK: - Write usage progress to shared file

    private func writeUsageProgress(limitId: String, minutesReached: Int?) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: sharedSuiteName
        ) else { return }

        let fileURL = containerURL.appendingPathComponent("limitUsageProgress.json")

        // Read existing progress
        var progress: [String: LimitProgress] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONDecoder().decode([String: LimitProgress].self, from: data) {
            progress = existing
        }

        // Determine minutes to write
        let minutes: Int
        if let m = minutesReached {
            minutes = m
        } else {
            // Final threshold — read limit minutes from config
            let limits = loadLimits()
            if let limit = limits.first(where: { $0.id.uuidString == limitId }) {
                minutes = limit.limitMinutes
            } else {
                minutes = progress[limitId]?.minutesUsed ?? 0
            }
        }

        // Only update if new value is higher (thresholds are cumulative within a day)
        let existing = progress[limitId]?.minutesUsed ?? 0
        if minutes >= existing {
            progress[limitId] = LimitProgress(
                minutesUsed: minutes,
                timestamp: Date()
            )
        }

        if let data = try? JSONEncoder().encode(progress) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func clearUsageProgress(limitId: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: sharedSuiteName
        ) else { return }

        let fileURL = containerURL.appendingPathComponent("limitUsageProgress.json")
        var progress: [String: LimitProgress] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONDecoder().decode([String: LimitProgress].self, from: data) {
            progress = existing
        }
        progress.removeValue(forKey: limitId)
        if let data = try? JSONEncoder().encode(progress) {
            try? data.write(to: fileURL, options: .atomic)
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
        guard let defaults = UserDefaults(suiteName: sharedSuiteName),
              let data = defaults.data(forKey: "blockRoutines"),
              let routines = try? JSONDecoder().decode([BlockRoutineData].self, from: data) else { return [] }
        return routines
    }

    private func loadLimits() -> [UsageLimitData] {
        guard let defaults = UserDefaults(suiteName: sharedSuiteName),
              let data = defaults.data(forKey: "usageLimits"),
              let limits = try? JSONDecoder().decode([UsageLimitData].self, from: data) else { return [] }
        return limits
    }
}

// Usage progress entry written by monitor, read by main app
private struct LimitProgress: Codable {
    let minutesUsed: Int
    let timestamp: Date
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
