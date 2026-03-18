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
    static let scorePreload = Self("Score Preload")
}

struct AppUsageData: Identifiable {
    let id = UUID()
    let displayName: String
    let duration: TimeInterval
    let formattedDuration: String
    let numberOfPickups: Int
}

struct DailyScore: Identifiable {
    let id = UUID()
    let dayLabel: String
    let score: Int
    let duration: TimeInterval
    let formattedDuration: String
    let isToday: Bool
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
    case digitalMonk

    var title: String {
        switch self {
        case .bingeWatcher: return "Binge Watcher"
        case .compulsiveChecker: return "Compulsive Checker"
        case .balancedDoom: return "Balanced Doom"
        case .digitalMonk: return "Digital Monk"
        }
    }

    var emoji: String {
        switch self {
        case .bingeWatcher: return "\u{1F37F}"
        case .compulsiveChecker: return "\u{1F440}"
        case .balancedDoom: return "\u{2696}\u{FE0F}"
        case .digitalMonk: return "\u{1F9D8}"
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
        case .digitalMonk:
            return "Minimal screen time and pickups. Are you even real?"
        }
    }

    var color: Color {
        switch self {
        case .bingeWatcher: return BrainRotTheme.neonPurple
        case .compulsiveChecker: return BrainRotTheme.neonPink
        case .balancedDoom: return BrainRotTheme.neonBlue
        case .digitalMonk: return BrainRotTheme.neonGreen
        }
    }
}

enum DoomAchievement: Identifiable {
    case grassToucher
    case terminalBrainrot
    case phoneAddict
    case marathonScroller
    case zenMaster
    case pickupArtist

    var id: String { title }

    var title: String {
        switch self {
        case .grassToucher: return "GRASS TOUCHER"
        case .terminalBrainrot: return "TERMINAL BRAINROT"
        case .phoneAddict: return "PHONE ADDICT"
        case .marathonScroller: return "MARATHON SCROLLER"
        case .zenMaster: return "ZEN MASTER"
        case .pickupArtist: return "PICKUP ARTIST"
        }
    }

    var emoji: String {
        switch self {
        case .grassToucher: return "\u{1F33F}"
        case .terminalBrainrot: return "\u{1F9E0}\u{1F480}"
        case .phoneAddict: return "\u{1F4F1}"
        case .marathonScroller: return "\u{23F1}\u{FE0F}"
        case .zenMaster: return "\u{1F9D8}"
        case .pickupArtist: return "\u{1F3AF}"
        }
    }

    var color: Color {
        switch self {
        case .grassToucher: return BrainRotTheme.neonGreen
        case .terminalBrainrot: return BrainRotTheme.neonPink
        case .phoneAddict: return BrainRotTheme.neonPurple
        case .marathonScroller: return BrainRotTheme.neonPink
        case .zenMaster: return BrainRotTheme.neonGreen
        case .pickupArtist: return BrainRotTheme.neonBlue
        }
    }

    var isPositive: Bool {
        switch self {
        case .grassToucher, .zenMaster: return true
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
