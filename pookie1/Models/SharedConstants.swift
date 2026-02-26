import Foundation
import SwiftUI
#if !targetEnvironment(simulator)
import DeviceActivity
#endif

enum AppGroupConstants {
    static let suiteName = "group.pookie1.pookie1.shared"
    static let selectionKey = "familyActivitySelection"
}

#if !targetEnvironment(simulator)
extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}
#endif
