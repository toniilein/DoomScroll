import DeviceActivity
import SwiftUI

@main
struct DeviceActivityReportExtensionMain: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { activityReport in
            TotalActivityView(activityReport: activityReport)
        }
    }
}
