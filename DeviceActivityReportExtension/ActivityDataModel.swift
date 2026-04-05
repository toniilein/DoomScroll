import DeviceActivity
import Foundation
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
    static let brainHealth = Self("Brain Health")
    static let weeklyTrend = Self("Weekly Trend")
    static let appAnalytics = Self("App Analytics")
    static let dayPills = Self("Day Pills")
    static let usageSummary = Self("Usage Summary")
    static let limitUsage = Self("Limit Usage")
    static let limitUsageDetail = Self("Limit Usage Detail")
    static let limitSlot0 = Self("Limit Slot 0")
    static let limitSlot1 = Self("Limit Slot 1")
    static let limitSlot2 = Self("Limit Slot 2")
    static let limitSlot3 = Self("Limit Slot 3")
    static let limitSlot4 = Self("Limit Slot 4")
}

struct AppUsageData: Identifiable {
    let id = UUID()
    let displayName: String
    let duration: TimeInterval
    let formattedDuration: String
    let numberOfPickups: Int
}

struct CategoryUsageData: Identifiable {
    let id = UUID()
    let categoryName: String
    let duration: TimeInterval
    let formattedDuration: String
    let pickups: Int
    let apps: [AppUsageData]
}

struct DailyScore: Identifiable {
    let id = UUID()
    let dayLabel: String
    let score: Int
    let duration: TimeInterval
    let formattedDuration: String
    let isToday: Bool
}

struct AppDailyUsage: Identifiable {
    let id = UUID()
    let displayName: String
    let dailyDurations: [TimeInterval]  // 7 entries, one per day (Mon→Sun or last 7 days)
    let totalDuration: TimeInterval
    let formattedTotal: String
    let dayLabels: [String]
}

struct WeeklyTrendData {
    let dailyScores: [DailyScore]
    let averageScore: Int
    let trend: TrendDirection
    let streakDays: Int
    let weeklyTotal: TimeInterval
    let formattedWeeklyTotal: String
    let bestDayIndex: Int?
    let worstDayIndex: Int?
}

enum TrendDirection {
    case improving, worsening, stable

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .worsening: return "Getting worse"
        case .stable: return "Stable"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .worsening: return "arrow.up.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return BrainRotTheme.neonGreen
        case .worsening: return BrainRotTheme.neonPink
        case .stable: return BrainRotTheme.neonBlue
        }
    }
}

// MARK: - Smart KPI Types

enum ScrollType {
    case bingeWatcher
    case compulsiveChecker
    case balancedDoom
    case zenMaster

    var title: String {
        switch self {
        case .bingeWatcher: return "Binge Watcher"
        case .compulsiveChecker: return "Compulsive Checker"
        case .balancedDoom: return "Balanced Doom"
        case .zenMaster: return "Zen Master"
        }
    }

    var emoji: String {
        switch self {
        case .bingeWatcher: return "\u{1F37F}"
        case .compulsiveChecker: return "\u{1F440}"
        case .balancedDoom: return "\u{2696}\u{FE0F}"
        case .zenMaster: return "\u{1F9D8}"
        }
    }

    var description: String {
        switch self {
        case .bingeWatcher:
            return "Few pickups but long sessions. You lock in and scroll for ages."
        case .compulsiveChecker:
            return "Tons of pickups, short sessions. You can't stop checking your phone."
        case .balancedDoom:
            return "Moderate sessions and pickups. Not great, not terrible."
        case .zenMaster:
            return "Minimal screen time and pickups. Are you even real?"
        }
    }

    var color: Color {
        switch self {
        case .bingeWatcher: return BrainRotTheme.neonPurple
        case .compulsiveChecker: return BrainRotTheme.neonPink
        case .balancedDoom: return BrainRotTheme.neonBlue
        case .zenMaster: return BrainRotTheme.neonGreen
        }
    }
}

enum DoomAchievement: Identifiable {
    case casualScroller
    case terminalBrainrot
    case phoneAddict
    case marathonScroller
    case zenMaster
    case pickupArtist

    var id: String { title }

    var title: String {
        switch self {
        case .casualScroller: return "CASUAL SCROLLER"
        case .terminalBrainrot: return "TERMINAL BRAINROT"
        case .phoneAddict: return "PHONE ADDICT"
        case .marathonScroller: return "MARATHON SCROLLER"
        case .zenMaster: return "ZEN MASTER"
        case .pickupArtist: return "PICKUP ARTIST"
        }
    }

    var emoji: String {
        switch self {
        case .casualScroller: return "\u{1F33F}"
        case .terminalBrainrot: return "\u{1F9E0}\u{1F480}"
        case .phoneAddict: return "\u{1F4F1}"
        case .marathonScroller: return "\u{23F1}\u{FE0F}"
        case .zenMaster: return "\u{1F9D8}"
        case .pickupArtist: return "\u{1F3AF}"
        }
    }

    var color: Color {
        switch self {
        case .casualScroller: return BrainRotTheme.neonGreen
        case .terminalBrainrot: return BrainRotTheme.neonPink
        case .phoneAddict: return BrainRotTheme.neonPurple
        case .marathonScroller: return BrainRotTheme.neonPink
        case .zenMaster: return BrainRotTheme.neonGreen
        case .pickupArtist: return BrainRotTheme.neonBlue
        }
    }

    var isPositive: Bool {
        switch self {
        case .casualScroller, .zenMaster: return true
        default: return false
        }
    }
}

// MARK: - Extended Data Models

struct SmartKPIs {
    let avgSessionMinutes: Double
    let pickupFrequencyMinutes: Double
    let doomRatioPercent: Double
    let doomRatioAppName: String
    let addictionIndex: Double
    let pickupsPerHour: Double
    let focusDestroyerApp: String
    let focusDestroyerPickups: Int
    let brainRemaining: Int
    let scrollType: ScrollType
    let achievements: [DoomAchievement]
}
