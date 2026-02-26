import Foundation

enum BrainRotCalculator {
    static func score(totalMinutes: Double) -> Int {
        let score: Double
        switch totalMinutes {
        case ..<0:
            score = 0
        case 0..<30:
            score = (totalMinutes / 30.0) * 20.0
        case 30..<60:
            score = 20.0 + ((totalMinutes - 30.0) / 30.0) * 20.0
        case 60..<120:
            score = 40.0 + ((totalMinutes - 60.0) / 60.0) * 25.0
        case 120..<240:
            score = 65.0 + ((totalMinutes - 120.0) / 120.0) * 20.0
        default:
            score = min(100, 85.0 + ((totalMinutes - 240.0) / 120.0) * 15.0)
        }
        return Int(min(100, max(0, score)))
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
