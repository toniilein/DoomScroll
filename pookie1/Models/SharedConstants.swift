import Foundation
import SwiftUI
#if !targetEnvironment(simulator)
import DeviceActivity
#endif

enum AppGroupConstants {
    static let suiteName = "group.pookie1.shared"
    static let selectionKey = "familyActivitySelection"
}

#if !targetEnvironment(simulator)
extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
    static let brainHealth = Self("Brain Health")
    static let weeklyTrend = Self("Weekly Trend")
    static let appAnalytics = Self("App Analytics")
    static let dayPills = Self("Day Pills")
    static let usageSummary = Self("Usage Summary")
    static let limitUsage = Self("Limit Usage")
    static let limitUsageDetail = Self("Limit Usage Detail")
    // Per-limit slots (one extension view per limit card)
    static let limitSlot0 = Self("Limit Slot 0")
    static let limitSlot1 = Self("Limit Slot 1")
    static let limitSlot2 = Self("Limit Slot 2")
    static let limitSlot3 = Self("Limit Slot 3")
    static let limitSlot4 = Self("Limit Slot 4")
}
#endif
