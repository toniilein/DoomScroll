import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct BrainHealthView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                if !screenTimeManager.isAuthorized {
                    ScrollView {
                        notAuthorizedState
                            .padding(.top)
                    }
                } else {
                    #if !targetEnvironment(simulator)
                    // Single report fills the whole screen. Weekly trend is now
                    // merged into the brain health report, so there's only ONE
                    // remote view. Its internal ScrollView handles scrolling.
                    DeviceActivityReport(.brainHealth, filter: screenTimeManager.weeklyFilter())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #endif
                }
            }
            .navigationTitle("Brain Health")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var notAuthorizedState: some View {
        VStack(spacing: 16) {
            Text("\u{1F9E0}")
                .font(.system(size: 60))
            Text("Screen Time Required")
                .font(.title2.bold())
                .foregroundColor(BrainRotTheme.textPrimary)
            Text("Enable Screen Time on the Overview tab to see your brain health data")
                .font(.body)
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
