import Foundation

enum SharedSettings {
    static let suiteName = "group.pookie1.shared"
    static let dailyLimitKey = "dailyLimitMinutes"
    static let defaultDailyLimit: Double = 240 // 4 hours

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static var dailyLimitMinutes: Double {
        get {
            let val = sharedDefaults.double(forKey: dailyLimitKey)
            return val > 0 ? val : defaultDailyLimit
        }
        set {
            sharedDefaults.set(newValue, forKey: dailyLimitKey)
        }
    }

    static func formatLimit(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}
