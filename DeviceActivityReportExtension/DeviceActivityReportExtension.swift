import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

@main
struct DoomScrollReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(activityData: totalActivity)
        }
        BrainHealthReport { healthData in
            BrainHealthReportView(healthData: healthData)
        }
        WeeklyTrendReport { trendData in
            WeeklyTrendView(trendData: trendData)
        }
        AppAnalyticsReport { analyticsData in
            AppAnalyticsView(data: analyticsData)
        }
        DayPillsReport { pillsData in
            DayPillsView(pillsData: pillsData)
        }
        UsageSummaryReport { summaryData in
            UsageSummaryView(data: summaryData)
        }
        LimitUsageReport { limitData in
            LimitUsageView(data: limitData)
        }
        LimitUsageDetailReport { detailData in
            LimitUsageDetailView(data: detailData)
        }
        LimitSlot0Report { d in SingleLimitBarView(data: d) }
        LimitSlot1Report { d in SingleLimitBarView(data: d) }
        LimitSlot2Report { d in SingleLimitBarView(data: d) }
        LimitSlot3Report { d in SingleLimitBarView(data: d) }
        LimitSlot4Report { d in SingleLimitBarView(data: d) }
    }
}
