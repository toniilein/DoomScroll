import Foundation
#if !targetEnvironment(simulator)
import FamilyControls
#endif

struct BlockRoutine: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var appSelectionData: Data?
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool = true
    var activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7] // 1=Sun..7=Sat
    var createdAt: Date = Date()

    var formattedTimeRange: String {
        let start = formatTime(hour: startHour, minute: startMinute)
        let end = formatTime(hour: endHour, minute: endMinute)
        return "\(start) \u{2013} \(end)"
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        if minute == 0 {
            return "\(h) \(period)"
        }
        return "\(h):\(String(format: "%02d", minute)) \(period)"
    }

    #if !targetEnvironment(simulator)
    var decodedSelection: FamilyActivitySelection {
        get {
            guard let data = appSelectionData else { return FamilyActivitySelection() }
            return (try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
        }
        set {
            appSelectionData = try? JSONEncoder().encode(newValue)
        }
    }

    var appCount: Int {
        decodedSelection.applicationTokens.count
    }

    var categoryCount: Int {
        decodedSelection.categoryTokens.count
    }

    var selectionSummary: String {
        let apps = appCount
        let cats = categoryCount
        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) app\(apps == 1 ? "" : "s")") }
        if cats > 0 { parts.append("\(cats) categor\(cats == 1 ? "y" : "ies")") }
        return parts.isEmpty ? "No apps selected" : parts.joined(separator: ", ")
    }
    #else
    var selectionSummary: String { "Simulator" }
    #endif
}

// MARK: - Usage Limit (block when time exceeded)

struct UsageLimit: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var appSelectionData: Data?
    var limitMinutes: Int // daily limit in minutes
    var isEnabled: Bool = true
    var activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7] // 1=Sun..7=Sat

    var formattedLimit: String {
        let hours = limitMinutes / 60
        let mins = limitMinutes % 60
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(mins)m"
    }

    #if !targetEnvironment(simulator)
    var decodedSelection: FamilyActivitySelection {
        get {
            guard let data = appSelectionData else { return FamilyActivitySelection() }
            return (try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
        }
        set {
            appSelectionData = try? JSONEncoder().encode(newValue)
        }
    }

    var selectionSummary: String {
        let apps = decodedSelection.applicationTokens.count
        let cats = decodedSelection.categoryTokens.count
        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) app\(apps == 1 ? "" : "s")") }
        if cats > 0 { parts.append("\(cats) categor\(cats == 1 ? "y" : "ies")") }
        return parts.isEmpty ? "No apps selected" : parts.joined(separator: ", ")
    }
    #else
    var selectionSummary: String { "Simulator" }
    #endif
}
