import Foundation
import Combine
#if !targetEnvironment(simulator)
import ManagedSettings
import DeviceActivity
import FamilyControls
#endif

@MainActor
class BlockingManager: ObservableObject {
    static let shared = BlockingManager()

    @Published var routines: [BlockRoutine] = []
    @Published var usageLimits: [UsageLimit] = []
    @Published var isQuickBlocking = false

    #if !targetEnvironment(simulator)
    private let center = DeviceActivityCenter()
    #endif

    private init() {
        seedDefaultRoutinesIfNeeded()
        routines = SharedSettings.blockRoutines
        usageLimits = SharedSettings.usageLimits
        isQuickBlocking = UserDefaults.standard.bool(forKey: "quickBlockActive")
    }

    // MARK: - Emergency Unblock All

    func unblockEverything() {
        #if !targetEnvironment(simulator)
        // Clear quick block
        let quickStore = ManagedSettingsStore(named: .init("quick_block"))
        quickStore.clearAllSettings()
        isQuickBlocking = false
        UserDefaults.standard.set(false, forKey: "quickBlockActive")

        // Clear all routine shields and stop monitoring
        for routine in routines {
            let store = ManagedSettingsStore(named: .init("routine_\(routine.id.uuidString)"))
            store.clearAllSettings()
            let activityName = DeviceActivityName("routine_\(routine.id.uuidString)")
            center.stopMonitoring([activityName])
        }

        // Clear all limit shields and stop monitoring
        for limit in usageLimits {
            let store = ManagedSettingsStore(named: .init("limit_\(limit.id.uuidString)"))
            store.clearAllSettings()
            let activityName = DeviceActivityName("limit_\(limit.id.uuidString)")
            center.stopMonitoring([activityName])
        }

        // Clear the default store too (catches anything else)
        let defaultStore = ManagedSettingsStore()
        defaultStore.clearAllSettings()

        // Disable all routines and limits
        for i in routines.indices {
            routines[i].isEnabled = false
        }
        for i in usageLimits.indices {
            usageLimits[i].isEnabled = false
        }

        // Save disabled state
        SharedSettings.blockRoutines = routines
        SharedSettings.usageLimits = usageLimits
        #endif
    }

    func reload() {
        routines = SharedSettings.blockRoutines
        usageLimits = SharedSettings.usageLimits
        isQuickBlocking = UserDefaults.standard.bool(forKey: "quickBlockActive")
    }

    // MARK: - Seed default routines on first launch

    private func seedDefaultRoutinesIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "blockRoutinesSeeded2") else { return }
        UserDefaults.standard.set(true, forKey: "blockRoutinesSeeded2")

        let defaults: [BlockRoutine] = [
            BlockRoutine(
                name: "Morning Focus",
                startHour: 6, startMinute: 0,
                endHour: 9, endMinute: 0,
                isEnabled: false
            ),
            BlockRoutine(
                name: "Work Mode",
                startHour: 9, startMinute: 0,
                endHour: 17, endMinute: 0,
                isEnabled: false
            ),
            BlockRoutine(
                name: "Night Wind Down",
                startHour: 21, startMinute: 0,
                endHour: 7, endMinute: 0,
                isEnabled: false
            ),
        ]

        for routine in defaults {
            SharedSettings.saveRoutine(routine)
        }

        // Pre-seed a Social Media usage limit (1 hour)
        let socialLimit = UsageLimit(
            name: "Social Media",
            limitMinutes: 60,
            isEnabled: false
        )
        SharedSettings.saveUsageLimit(socialLimit)
    }

    // MARK: - Quick Block (instant on/off with custom selection)

    #if !targetEnvironment(simulator)
    func saveQuickBlockSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: "quickBlockSelection")
        }
        // If currently blocking, re-apply with new selection
        if isQuickBlocking {
            let store = ManagedSettingsStore(named: .init("quick_block"))
            store.clearAllSettings()
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }
            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }
            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
            }
        }
    }

    func loadQuickBlockSelection() -> FamilyActivitySelection {
        guard let data = UserDefaults.standard.data(forKey: "quickBlockSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }
    #endif

    func toggleQuickBlock() {
        #if !targetEnvironment(simulator)
        if isQuickBlocking {
            let store = ManagedSettingsStore(named: .init("quick_block"))
            store.clearAllSettings()
            isQuickBlocking = false
            UserDefaults.standard.set(false, forKey: "quickBlockActive")
        } else {
            let selection = loadQuickBlockSelection()
            let store = ManagedSettingsStore(named: .init("quick_block"))

            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }
            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }
            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
            }
            isQuickBlocking = true
            UserDefaults.standard.set(true, forKey: "quickBlockActive")
        }
        #endif
    }

    // MARK: - Usage Limits

    func saveUsageLimit(_ limit: UsageLimit) {
        SharedSettings.saveUsageLimit(limit)
        usageLimits = SharedSettings.usageLimits

        // Write per-limit config so extension can read it
        syncLimitToSharedDefaults(limit)

        if limit.isEnabled {
            startLimitMonitoring(limit)
        } else {
            stopLimitMonitoring(limit)
            removeLimitShield(limit)
        }
    }

    private func syncLimitToSharedDefaults(_ limit: UsageLimit) {
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let id = limit.id.uuidString

        shared?.set(limit.limitMinutes, forKey: "limit_\(id)_minutes")
        shared?.set(limit.isEnabled, forKey: "limit_\(id)_enabled")
        shared?.set(limit.appSelectionData, forKey: "limit_\(id)_selectionData")

        // Update master list of limit IDs
        var allIds = shared?.stringArray(forKey: "allLimitIds") ?? []
        if !allIds.contains(id) {
            allIds.append(id)
            shared?.set(allIds, forKey: "allLimitIds")
        }

        shared?.synchronize()
    }

    func deleteUsageLimit(_ limit: UsageLimit) {
        stopLimitMonitoring(limit)
        removeLimitShield(limit)
        SharedSettings.deleteUsageLimit(id: limit.id)
        usageLimits = SharedSettings.usageLimits

        // Clean up per-limit shared defaults
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let id = limit.id.uuidString
        shared?.removeObject(forKey: "limit_\(id)_minutes")
        shared?.removeObject(forKey: "limit_\(id)_enabled")
        shared?.removeObject(forKey: "limit_\(id)_selectionData")
        var allIds = shared?.stringArray(forKey: "allLimitIds") ?? []
        allIds.removeAll { $0 == id }
        shared?.set(allIds, forKey: "allLimitIds")
        shared?.synchronize()
    }

    func toggleUsageLimit(_ limit: UsageLimit) {
        var updated = limit
        updated.isEnabled.toggle()
        saveUsageLimit(updated)
    }

    private func startLimitMonitoring(_ limit: UsageLimit) {
        #if !targetEnvironment(simulator)
        let selection = limit.decodedSelection
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let eventName = DeviceActivityEvent.Name("limit_\(limit.id.uuidString)")
        let threshold = DateComponents(minute: limit.limitMinutes)

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: threshold
        )

        let activityName = DeviceActivityName("limit_\(limit.id.uuidString)")

        // Stop any existing monitoring first
        center.stopMonitoring([activityName])

        do {
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
        } catch {
            print("Failed to start limit monitoring \(limit.name): \(error)")
        }
        #endif
    }

    private func stopLimitMonitoring(_ limit: UsageLimit) {
        #if !targetEnvironment(simulator)
        let activityName = DeviceActivityName("limit_\(limit.id.uuidString)")
        center.stopMonitoring([activityName])
        #endif
    }

    private func removeLimitShield(_ limit: UsageLimit) {
        #if !targetEnvironment(simulator)
        let store = ManagedSettingsStore(named: .init("limit_\(limit.id.uuidString)"))
        store.clearAllSettings()
        #endif
    }

    func syncAllLimits() {
        for limit in usageLimits {
            if limit.isEnabled {
                startLimitMonitoring(limit)
            } else {
                stopLimitMonitoring(limit)
                removeLimitShield(limit)
            }
        }
    }

    // MARK: - CRUD

    func saveRoutine(_ routine: BlockRoutine) {
        SharedSettings.saveRoutine(routine)
        routines = SharedSettings.blockRoutines

        if routine.isEnabled {
            startMonitoring(routine)
            applyIfActive(routine)
        } else {
            stopMonitoring(routine)
            removeShield(routine)
        }
    }

    func deleteRoutine(_ routine: BlockRoutine) {
        stopMonitoring(routine)
        removeShield(routine)
        SharedSettings.deleteRoutine(id: routine.id)
        routines = SharedSettings.blockRoutines
    }

    func toggleRoutine(_ routine: BlockRoutine) {
        var updated = routine
        updated.isEnabled.toggle()
        saveRoutine(updated)
    }

    // MARK: - Sync all schedules (call on app launch)

    func syncAllSchedules() {
        for routine in routines {
            if routine.isEnabled {
                startMonitoring(routine)
                applyIfActive(routine)
            } else {
                stopMonitoring(routine)
                removeShield(routine)
            }
        }
        syncAllLimits()
    }

    // MARK: - DeviceActivityCenter Scheduling

    private func startMonitoring(_ routine: BlockRoutine) {
        #if !targetEnvironment(simulator)
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: routine.startHour, minute: routine.startMinute),
            intervalEnd: DateComponents(hour: routine.endHour, minute: routine.endMinute),
            repeats: true
        )

        let activityName = DeviceActivityName("routine_\(routine.id.uuidString)")

        do {
            try center.startMonitoring(activityName, during: schedule)
        } catch {
            print("Failed to start monitoring routine \(routine.name): \(error)")
        }
        #endif
    }

    private func stopMonitoring(_ routine: BlockRoutine) {
        #if !targetEnvironment(simulator)
        let activityName = DeviceActivityName("routine_\(routine.id.uuidString)")
        center.stopMonitoring([activityName])
        #endif
    }

    // MARK: - ManagedSettingsStore

    func applyShield(_ routine: BlockRoutine) {
        #if !targetEnvironment(simulator)
        let store = ManagedSettingsStore(named: .init("routine_\(routine.id.uuidString)"))
        let selection = routine.decodedSelection

        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        }
        #endif
    }

    func removeShield(_ routine: BlockRoutine) {
        #if !targetEnvironment(simulator)
        let store = ManagedSettingsStore(named: .init("routine_\(routine.id.uuidString)"))
        store.clearAllSettings()
        #endif
    }

    // MARK: - Check if routine is currently active

    private func applyIfActive(_ routine: BlockRoutine) {
        guard routine.isEnabled else { return }

        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let startMinutes = routine.startHour * 60 + routine.startMinute
        let endMinutes = routine.endHour * 60 + routine.endMinute

        let isActive: Bool
        if startMinutes <= endMinutes {
            isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            isActive = currentMinutes >= startMinutes || currentMinutes < endMinutes
        }

        if isActive {
            applyShield(routine)
        }
    }
}

// MARK: - Static helpers for the monitor extension

enum BlockingHelper {
    static func applyShieldForRoutine(id: String) {
        #if !targetEnvironment(simulator)
        let routines = SharedSettings.blockRoutines
        guard let routine = routines.first(where: { $0.id.uuidString == id }) else { return }
        guard routine.isEnabled else { return }

        let store = ManagedSettingsStore(named: .init("routine_\(id)"))
        let selection = routine.decodedSelection

        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        }
        #endif
    }

    static func removeShieldForRoutine(id: String) {
        #if !targetEnvironment(simulator)
        let store = ManagedSettingsStore(named: .init("routine_\(id)"))
        store.clearAllSettings()
        #endif
    }
}
