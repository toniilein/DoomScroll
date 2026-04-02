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
            // Daily reset: clear the limit shield at end of day
            let id = String(raw.dropFirst("limit_".count))
            let store = ManagedSettingsStore(named: .init("limit_\(id)"))
            store.clearAllSettings()
        }
    }

    // MARK: - Usage limit threshold callback

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        let raw = event.rawValue
        if raw.hasPrefix("limit_") {
            let id = String(raw.dropFirst("limit_".count))
            applyLimitShield(id: id)
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
}
