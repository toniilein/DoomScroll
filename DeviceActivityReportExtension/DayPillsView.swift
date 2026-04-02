import SwiftUI

struct DayPillsView: View {
    let pillsData: DayPillsData

    var body: some View {
        // Minimal visible view — just needs to exist so the extension processes the data.
        // The actual pill UI is rendered by the main app.
        Color.clear.frame(height: 1)
    }
}
