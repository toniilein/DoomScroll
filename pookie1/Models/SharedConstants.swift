import Foundation
import DeviceActivity

enum AppGroupConstants {
    static let suiteName = "group.pookie1.pookie1.shared"
    static let selectionKey = "familyActivitySelection"
}

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}
